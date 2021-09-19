require "../../../helpers/base/parser"
require "./lexer"
require "./tokens"
require "./rules"
require "../../../helpers/base/parser"

module CLDR::Numbers
  # EXPERIMENTAL
  # TODO Write documentation
  #
  # (Mostly) Based of off the pattern BNF specified in ICU4C's DecimalFormat docs
  # See https://unicode-org.github.io/icu-docs/apidoc/released/icu4c/classicu_1_1DecimalFormat.html
  #
  # Note that the grammar there is far stricter than other implementations like Python's babel
  # or Ruby's RubyTwitterCLDR's, but still not as strict as pure ICU.
  class PatternParser < Lens::Base::Parser(Token, TokenTypes, PatternLexer)
    def initialize(source : String)
      super(source)
      @rules = [] of Rules::Rules
      @metadata = Metadata.new
    end

    private def pattern
      positive_pattern = self.subpattern

      # TODO
      # negative_pattern = nil
      # if self.match(TokenTypes::SubPatternBoundary)
      #   negative_pattern = self.subpattern(negative: true)
      # end

      return positive_pattern.to_a.flatten
    end

    private def subpattern(negative = false)
      prefix = self.affix
      number = self.number
      suffix = self.affix

      return prefix, number, suffix
    end

    private def number
      return self.integer + self.fractional_format
    end

    private def affix
      affix_rules = [] of Rules::Rules

      # Before an affix
      self.pad_spec

      while self.match(TokenTypes::PercentSign, TokenTypes::PerMilleSign, TokenTypes::CurrencySymbol,
              TokenTypes::StringLiteral, TokenTypes::Character)
        if @previous_token.token_type == TokenTypes::Character
          affix_rules << Rules::InjectCharacter.new(@previous_token.literal.as(String))
        else
          affix_rules << Rules::InjectSymbol.new(@previous_token.token_type)
        end
      end

      # After an affix
      self.pad_spec

      return affix_rules
    end

    private def pad_spec(negative = false)
      if self.match(TokenTypes::PaddingSignifier)
        if @metadata.use_padding
          raise LensExceptions::ParseError.new("The padding specifier, '*' can only appear once, either before the prefix, " + \
            "after the prefix, before the suffix, or after the suffix.")
        end

        # Negative patterns are only there to specify explicit +- so it shouldn't
        # have any effect on the end-result
        if !negative
          @metadata.use_padding = true
          @metadata.padding_character = @previous_token.literal.as(String)
        end
      end
    end

    # Parse the rest of the integer pattern as a significant figure pattern.
    #
    # Almost the exact same as the integer pattern, except it also parses significant figure specifications
    # into the metadata.
    #
    # Takes in an array of grouping sizes, and the known size of the in-process of parsing grouping block.
    private def sigdigits(groups = nil, grouping_block_count = nil)
      groups ||= [] of Int32
      grouping_block_count ||= 0

      additional_significant_figures_count = 0
      minimum_significant_figures = 1 # Already matched at least one
      matched_significant_figure_signifier = true
      # Match remaining @s
      while self.match(TokenTypes::SignificantDigitSignifier)
        grouping_block_count += 1
        minimum_significant_figures += 1
      end

      # Match remaining #s and @s in initial significant figure signifier block
      while self.match(TokenTypes::DigitPlaceholder, TokenTypes::DigitPlaceholderNoFrontBackZeros)
        grouping_block_count += 1
        additional_significant_figures_count += 1
      end

      # Whether or not this block also effects grouping size depends on if there's already an grouping block. IE
      #
      # ###,@### has a primary grouping size of 4 and no secondary grouping
      # @###,### has a primary group of 3 and no secondary grouping. The initial signifier block, is ignored.
      if groups.size >= 1 && (self.is_at_end? || self.match(TokenTypes::GroupingSeparator) || {TokenTypes::CurrencySymbol, TokenTypes::DecimalSeparator}.includes? @current_token.token_type)
        groups << grouping_block_count
        grouping_block_count = 0
      else
        grouping_block_count = 0
      end

      self.match(TokenTypes::GroupingSeparator)

      while self.match(TokenTypes::DigitPlaceholder, TokenTypes::DigitPlaceholderNoFrontBackZeros)
        grouping_block_count += 1
        additional_significant_figures_count += 1

        # Are we at the start of another grouping block or are we at the end of the numerical body.
        # We're also not using consume here in order to not advance the token iterator the token.

        if self.is_at_end? || self.match(TokenTypes::GroupingSeparator) || {TokenTypes::CurrencySymbol, TokenTypes::DecimalSeparator}.includes? @current_token.token_type
          # Trailing and leading zeros are meaningless sigdigit patterns
          groups << grouping_block_count
          grouping_block_count = 0
        end
      end

      # Rows of @s can only exist once, anything else doesn't make sense:
      #
      # if @s details the minimum number of sigifgs
      # and #s details the remaining maximum number of sigfigs
      #
      # how would we parse another @s in a separate block? We can't. It's illegal.
      #
      if self.match(TokenTypes::SignificantDigitSignifier)
        raise LensExceptions::ParseError.new("Blocks containing @s in a row can only appear once in a pattern.")
      end

      # Only the last two actually matters according to CLDR number pattern spec.
      if groups.size > 2
        groups = groups[-2..]
      end

      # Configure Grouping
      if groups.size == 2
        @metadata.secondary_grouping = groups[0]
        @metadata.primary_grouping = groups[1]
      elsif groups.size == 1
        @metadata.primary_grouping = groups[0]
      end

      # Configure Significant figures
      @metadata.minimum_significant_figures = minimum_significant_figures
      @metadata.maximum_significant_figures = minimum_significant_figures + additional_significant_figures_count

      if !groups.empty?
        return [Rules::Integer.new(false, false)]
      else
        return [] of Rules::Rules
      end
    end

    # Matches the integer portion of the number pattern which can contain
    # grouping and sigfigs information.
    #
    # Differs from ICU specs as we allow intermediate
    # #s and 0s. Just that only the first and last 0 has any effect.
    private def integer
      groups = [] of Int32
      grouping_block_count = 0
      leading_zero = false
      trailing_zero = false

      if self.match(TokenTypes::DigitPlaceholder)
        leading_zero = true
      end

      # We match the grouping separator in order to handle cases like
      #
      # #,### (primary grouping value of 3 and no secondary grouping)
      # @## (No grouping values at all)
      matched_blocks = 0

      while self.match(TokenTypes::DigitPlaceholderNoFrontBackZeros, TokenTypes::DigitPlaceholder, TokenTypes::SignificantDigitSignifier)
        grouping_block_count += 1

        # If the matched token is a significant figure signifier we'll go ahead and parse the rest of this integer block
        # with those in mind.
        if @previous_token.token_type == TokenTypes::SignificantDigitSignifier
          # In the ICU version, it'll error when we have "0"s in this expression. However, as are already more
          # lenient than it by allowing intermediate 0s between #s (albeit meaningless except as grouping size counts)
          # I don't see why we shouldn't also allow it in sigfig pattern, but interpreted the same as #s.
          return self.sigdigits(groups, grouping_block_count)
        end

        # Do we allow trailing zeros? (This should be the "last") '0' token
        if ((@previous_token.token_type == TokenTypes::DigitPlaceholder && {TokenTypes::CurrencySymbol, TokenTypes::DecimalSeparator}.includes? @current_token.token_type) || \
              (@previous_token.token_type == TokenTypes::DigitPlaceholder && self.is_at_end?))
          trailing_zero = true
        end

        # Are we at the start of another grouping block or are we at the end of the numerical body.
        # We're also not using consume here in order to not advance the token iterator the token.
        if self.is_at_end? || self.match(TokenTypes::GroupingSeparator) || {TokenTypes::CurrencySymbol, TokenTypes::DecimalSeparator}.includes? @current_token.token_type
          groups << grouping_block_count
          grouping_block_count = 0
        end
      end

      # First grouping block is meaningless. IE #,### is *only* a primary group of 3 without any secondary groups.
      groups = groups[1..] if !groups.empty?

      # Only the last two actually matters
      if groups.size > 2
        groups = groups[-2..]
      end

      # Configure metadata
      # Grouping
      if groups.size == 2
        @metadata.secondary_grouping = groups[0]
        @metadata.primary_grouping = groups[1]
      elsif groups.size == 1
        @metadata.primary_grouping = groups[0]
      end

      if !groups.empty?
        return [Rules::Integer.new(leading_zero, trailing_zero)]
      else
        return [Rules::Integer.new(leading_zero, trailing_zero)]
      end
    end

    # Matches fractional part of number pattern
    private def fractional_format
      fractional_rules = [] of Rules::Rules

      groups = [] of Int32
      grouping_block_count = 0

      leading_zero = false
      trailing_zero = false
      fractional_count = 0

      # Similar to #integer but without calls to #sigdigits and doesn't parse into Group rules
      if self.match(TokenTypes::CurrencySymbol, TokenTypes::DecimalSeparator)
        fractional_rules << Rules::InjectSymbol.new(@previous_token.token_type)

        if self.check(TokenTypes::DigitPlaceholder)
          leading_zero = true
        end

        while self.match(TokenTypes::DigitPlaceholderNoFrontBackZeros, TokenTypes::DigitPlaceholder)
          grouping_block_count += 1
          fractional_count += 1

          # Do we allow trailing zeros? (This should be the "last") '0' token
          if @previous_token.token_type == TokenTypes::DigitPlaceholder && self.is_at_end?
            trailing_zero = true
          end

          # Are we at the start of another grouping block or are we at the end of the numerical body.
          if (self.is_at_end? && groups.size > 0) || self.match(TokenTypes::GroupingSeparator)
            groups << grouping_block_count
            grouping_block_count = 0
          end
        end

        # 0.First grouping block is meaningless. IE #,### is *only* a fractional primary group of 3 without any fractional secondary groups.
        groups = groups[1..] if !groups.empty?

        # Configure grouping metadata for fractional values
        if !groups.empty?
          # Only the last two actually matters
          if groups.size > 2
            groups = groups[-2..]
          end

          # Configure metadata
          # Grouping
          if groups.size == 2
            @metadata.fractional_secondary_grouping = groups[0]
            @metadata.fractional_primary_grouping = groups[1]
          elsif groups.size == 1
            @metadata.fractional_primary_grouping = groups[0]
          end
        end

        if fractional_count != 0
          fractional_rules << Rules::Fractional.new(leading_zero, trailing_zero, fractional_count)
        end
      end

      fractional_rules
    end

    # TODO add support for negative patterns

    # Parse a number pattern
    def parse
      self.token_reader do |token|
        r = self.pattern
        @rules += r if r
      end

      return @rules, @metadata
    end
  end
end

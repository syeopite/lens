require "./lexer"
require "./tokens"
require "./rules"

module CLDR::Numbers
  # EXPERIMENTAL
  # TODO Write documentation
  class PatternParser < Lens::Base::Parser(Token, TokenTypes, PatternLexer)
    def initialize(source : String)
      super(source)
      @rules = [] of Rules::Rules
      @fractional_rules = [] of Rules::Rules
      @metadata = Metadata.new
    end

    # Matches a decimal format
    def decimal_format
      return self.prefix
    end

    # Matches a number pattern prefix
    def prefix
      while self.match(TokenTypes::PercentSign, TokenTypes::PerMilleSign,
              TokenTypes::CurrencySymbol, TokenTypes::StringLiteral)
        @rules << Rules::InjectSymbol.new(@previous_token.token_type)
      end

      if self.match(TokenTypes::PaddingSignifier)
        @metadata.use_padding = true
        @metadata.padding_character = @previous_token.literal.as(String)
      end

      self.number_format
    end

    # Matches the body of the number format (grouping, sigfigs, etc)
    def number_format
      groups = [] of Rules::Group
      grouping_count = 0

      leading_zero = false
      trailing_zero = false

      max_sigfig_count = 0
      calculate_sigfig = false

      # Handling grouping and significant digits embeded in grouping expressions
      while self.match(TokenTypes::GroupingSeparator, TokenTypes::SignificantDigitSignifier)
        # This shouldn't be accumulated over multiple sections.
        max_sigfig_count = 0

        if self.check(TokenTypes::DigitPlaceholder)
          leading_zero = true
        end

        if @previous_token.token_type == TokenTypes::SignificantDigitSignifier
          minimum_significant_figures = @previous_token.literal
          calculate_sigfig = true
        end

        while self.match(TokenTypes::DigitPlaceholderNoFrontBackZeros, TokenTypes::DigitPlaceholder)
          grouping_count += 1
          if calculate_sigfig
            max_sigfig_count = max_sigfig_count + 1
          end
        end

        if @previous_token.token_type == TokenTypes::DigitPlaceholder
          trailing_zero = true
        end

        # Start of new grouping block? Or are we at the end of the grouping sections.
        # We're also not using consume here in order to not advance the token iterator the token.
        if @current_token.token_type == TokenTypes::GroupingSeparator || @current_token.token_type == TokenTypes::DecimalSeparator
          groups << Rules::Group.new(leading_zero, trailing_zero, grouping_count)
          leading_zero = false
          trailing_zero = false
          grouping_count = 0
        end
      end

      if !groups.empty?
        if grouping_count != 0
          groups << Rules::Group.new(leading_zero, trailing_zero, grouping_count)
        end

        # Only the last two actually matters
        if groups.size > 2
          groups = groups[-2..]
        end
      end

      # Configure metadata
      # Grouping
      if groups.size == 2
        @metadata.secondary_grouping = groups[0].size
        @metadata.primary_grouping = groups[1].size
      elsif groups.size == 1
        @metadata.primary_grouping = groups[0].size
      end

      # Significant figures
      if max_sigfig_count != 0
        @metadata.minimum_significant_figures = minimum_significant_figures.as(Int32)
        @metadata.maximum_significant_figures = minimum_significant_figures.as(Int32) + max_sigfig_count
      end

      @rules += groups
      return self.fractional_format
    end

    # Matches fractional part of number pattern
    def fractional_format
      fractional_rules = [] of Rules::Rules
      leading_zero = false
      trailing_zero = false
      fractional_count = 0

      if self.match(TokenTypes::CurrencySymbol, TokenTypes::DecimalSeparator)
        fractional_rules << Rules::InjectSymbol.new(@previous_token.token_type)

        if self.check(TokenTypes::DigitPlaceholder)
          leading_zero = true
        end

        while self.match(TokenTypes::DigitPlaceholderNoFrontBackZeros, TokenTypes::DigitPlaceholder)
          fractional_count += 1
        end

        if @previous_token.token_type == TokenTypes::DigitPlaceholder
          trailing_zero = true
        end

        if fractional_count != 0
          fractional_rules << Rules::Fractional.new(leading_zero, trailing_zero, fractional_count)
        end
      end

      @fractional_rules += fractional_rules
      self.suffix
    end

    # Matches suffix of number pattern
    def suffix
      while self.match(TokenTypes::PercentSign, TokenTypes::PerMilleSign,
              TokenTypes::CurrencySymbol, TokenTypes::StringLiteral)
        @rules << Rules::InjectSymbol.new(@previous_token.token_type)
      end

      if self.match(TokenTypes::PaddingSignifier)
        @metadata.use_padding = true
        @metadata.padding_character = @previous_token.literal.as(String)
      end
    end

    # TODO add support for negative patterns

    # Parse a number pattern
    def parse
      self.token_reader do |token|
        self.decimal_format
      end

      return @rules, @fractional_rules, @metadata
    end
  end
end

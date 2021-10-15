module CLDR::Numbers
  # EXPERIMENTAL
  #
  # Formatter for formatting decimal numbers with the attributes from the selected language,
  # and the parsed results from a pattern.
  #
  # ```
  # rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.###").parse
  # formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)
  # ```
  class PatternFormatter(Lang)
    @instructions : PatternConstruct
    @metadata : Metadata
    @reader : Char::Reader

    # Initializes a decimal formatter with the parsed results from the `PatternParser`.
    #
    # ```
    # rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.###").parse
    # formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)
    #
    # formatter.format("12345")     # => 12,345
    # formatter.format("1000.1236") # => 1,000.124
    # ```
    def initialize(@instructions : PatternConstruct, @metadata : Metadata)
      @reader = Char::Reader.new("") # Dummy
    end

    # Add X amount of digits to the formatted number from the current @reader.
    private def add_number_to_str_x_times(io, times)
      times.times do
        char = @reader.current_char
        if char == '\0'
          return false
        end

        io << char
        @reader.next_char
      end

      return true
    end

    # Handles the grouping of numbers of a numerical component
    #
    # CLDR defines two grouping types.
    # - Primary | Least significant digits
    # - Secondary | Everything else
    #
    # For most languages, they are the same size. However, some such as Hindi have
    # different values. Because of that, we need to handle both separately.
    #
    # Recall that during parsing, we made it so that when the primary_group is equal to the secondary_group,
    # the secondary_group attribute would be unset within @metadata and remain as nil.
    # (# TODO remove this restriction for simplification)
    #
    #
    # This means that this method has three different paths:
    #
    # 1. To handle the case where there is only a primary group, as in all the
    # are split into chunks of primary grouping sizes.
    # 2. To handle the case where both groups are unset
    # 3. To handle the case of grouping the first  X (of primary grouping sizes) amount of
    # numbers and **only** the first X amount.
    # 4. Split leftover numbers into chunks of secondary grouping sizes.
    #
    private def handle_group(io, component_size, primary, secondary)
      if !secondary
        # Handle the case in which no grouping is configured
        return self.add_remaining_characters_to_io(io) if !primary

        while (component_size - @reader.pos) != 0
          status = self.add_number_to_str_x_times(io, primary.not_nil!)

          if !status
            break
          end

          # Check again that we're still able to group. If so, start the next portion with a marker.
          if (component_size - @reader.pos) >= primary
            io << Lang::GroupSymbol
          elsif 0 < (component_size - @reader.pos) < primary # Last
            io << Lang::GroupSymbol
          end
        end
      else
        # First we handle the primary grouping
        self.add_number_to_str_x_times(io, primary.not_nil!)

        # If there's still enough characters to *potentially* create a secondary group,
        # then we'll go ahead and add the marker.
        if (component_size - @reader.pos) != 0
          io << Lang::GroupSymbol
        end

        # Now we handle the second secondary
        while (component_size - @reader.pos) >= secondary
          status = self.add_number_to_str_x_times(io, secondary.not_nil!)
          # It only returns false when we're at at the end of source.
          # TODO refactor variable name to be more intuitive.
          if !status
            break
          end

          # Check again that we're still able to group. If so, start the next portion with a marker.
          if (component_size - @reader.pos) != secondary
            io << Lang::GroupSymbol
          elsif 0 < (component_size - @reader.pos) < secondary # Last
            io << Lang::GroupSymbol
          end
        end

        # Handle any remaining ungrouped numbers
        return self.add_remaining_characters_to_io(io)
      end
    end

    # Adds remaining characters from the current numerical body in processing to formatted number
    private def add_remaining_characters_to_io(io)
      while @reader.current_char != '\0'
        io << @reader.current_char
        @reader.next_char
      end
    end

    # Normalize integer with respect to the amount of leading zeros edibility
    private def normalize_integer_size(integer, forbidden_leading_zero_count)
      return integer if forbidden_leading_zero_count == 0
      leading_zero_count = count_zeros_of_string_encoded_number(integer, direction: true)
      return integer if leading_zero_count == 0

      integer = (
        if forbidden_leading_zero_count > leading_zero_count
          integer[leading_zero_count..]
        elsif forbidden_leading_zero_count <= leading_zero_count
          integer[forbidden_leading_zero_count..]
        else
          integer
        end
      )

      return integer
    end

    # Normalize fraction size with respect to maximum, minimum digits and trailing zeros edibility
    private def normalize_fraction_size(fractional, rule : Rules::Fractional)
      # When the amount of fraction digits exceeds what the pattern allows
      # then we'll do a half-even (ties_even) rounding to get it to the maximums
      # size the rule allows.
      if fractional.size > rule.size
        processed = "0.#{fractional}".to_f64.round(rule.size, mode: :ties_even).to_s[2..]

        # When the amount of fractional digits is less than the amount required by the rules we'll go ahead
        # and add trailing zeros
      elsif fractional.size < rule.size
        processed = (fractional + "0" * (rule.size - fractional.size))
      else
        processed = fractional
      end

      return processed if rule.forbidden_trailing_zero_count == 0
      trailing_zero_count = count_zeros_of_string_encoded_number(processed, direction: false)
      return processed if trailing_zero_count == 0

      processed = (
        if rule.forbidden_trailing_zero_count > trailing_zero_count
          processed[...-trailing_zero_count]
        elsif rule.forbidden_trailing_zero_count <= trailing_zero_count
          processed[...-rule.forbidden_trailing_zero_count]
        else
          processed
        end
      )

      return processed
    end

    # Replace special character rule with the corresponding character in the selected locale.
    private def inject_symbol(str, rule : Rules::InjectSymbol)
      str << case rule.character
      when TokenTypes::DecimalSeparator
        Lang::DecimalSymbol
      when TokenTypes::MinusSign
        Lang::MinusSignSymbol
      when TokenTypes::GroupingSeparator
        Lang::GroupSymbol
      when TokenTypes::ExponentialSeparator
        Lang::ExponentialSymbol
      when TokenTypes::PlusSign
        Lang::PlusSignSymbol
      when TokenTypes::PercentSign
        Lang::PercentSignSymbol
      when TokenTypes::PerMilleSign
        Lang::PerMilleSymbol
        # when CurrencySymbol
        #   Lang::CurrencySymbol
      else
        raise "Unknown character"
      end
    end

    # Creates and returns the formatted affix based on the parsed ruleset for either the prefix or suffix.
    private def format_affix(ruleset)
      formatted_affix = String.build do |io|
        ruleset.each do |rule|
          case rule
          when Rules::InjectSymbol     then self.inject_symbol(io, rule)
          when Rules::InjectCharacters then io << rule.character
          end
        end
      end

      return formatted_affix
    end

    # Internal method for handling number formats.
    private def internal_format(integer, fractional, negative = false, sig_pattern = false)
      # Construct instructions for the specific number
      if negative
        # Use default prefix but with addition of a minus sign in front when none
        # explicit negative affixes are given
        if !@instructions.negative_prefix && !@instructions.negative_suffix
          prefix = [Rules::InjectSymbol.new(TokenTypes::MinusSign)] + @instructions.prefix
          suffix = @instructions.suffix
        else
          prefix = @instructions.negative_prefix || @instructions.prefix
          suffix = @instructions.negative_suffix || @instructions.suffix
        end
      else
        prefix = @instructions.prefix
        suffix = @instructions.suffix
      end

      formatted_prefix = self.format_affix(prefix)

      formatted_int = String.build do |io|
        integer = normalize_integer_size(integer, @instructions.integer[0].as(Rules::Integer).forbidden_leading_zero_count)
        @reader = Char::Reader.new(integer.reverse)
        self.handle_group(io, integer.size, @metadata.primary_grouping, @metadata.secondary_grouping)
      end

      formatted_fractional = String.build do |io|
        break if fractional.empty?

        @instructions.fractional.each do |rule|
          case rule
          when Rules::InjectSymbol then self.inject_symbol(io, rule)
          when Rules::Fractional
            fractional = normalize_fraction_size(fractional, rule)
            @reader = Char::Reader.new(fractional.reverse)

            grouped = String.build do |fractional_grouping_io|
              self.handle_group(fractional_grouping_io, fractional.size, @metadata.fractional_primary_grouping, @metadata.fractional_secondary_grouping)
            end

            io << grouped.reverse
          end
        end

        # Significant figure patterns have empty fractional rulesets. However, we'll still have to add
        # the decimal values to the final formatted result. And we also know we can do this because the total
        # amount of sig digits is less than or equal to the maximum allowed.
        if sig_pattern && @instructions.fractional.empty?
          io << "#{Lang::DecimalSymbol}#{fractional}"
        end
      end

      # Pads with 0 if the total sigfig count is less than the minimum.
      if sig_pattern
        if fractional.empty?
          total_sig_figs = (integer.rstrip("0").size)
        else
          if integer == "0"
            # Since the integer portion is 0, we'll need to strip the leading zeros
            # from the fractional part in order to find the remaining siginfnicant digits. IE:
            # 0.003 has only one sigfig
            total_sig_figs = (integer.rstrip("0").size + fractional.lstrip("0").size)
          else
            total_sig_figs = (integer.rstrip("0").size + fractional.size)
          end
        end

        if total_sig_figs < @metadata.minimum_significant_figures.not_nil! && total_sig_figs != 0
          to_pad_amount = @metadata.minimum_significant_figures.not_nil! - total_sig_figs

          if fractional.empty?
            formatted_fractional = "#{Lang::DecimalSymbol}"
          end

          formatted_fractional = formatted_fractional.not_nil! + ("0" * to_pad_amount)
        end
      end

      formatted_suffix = self.format_affix(suffix)
      return "#{formatted_prefix}#{formatted_int.reverse}#{formatted_fractional}#{formatted_suffix}"
    end

    # Preserves X amounts of significant digits
    #
    # Pretty much an wrapper for Number.significant
    private def round_significant(number)
      if number.is_a? Float
        digits = number.to_s.size - 1 # Decimal point
      else
        digits = number.to_s.size
      end

      if digits >= @metadata.maximum_significant_figures.not_nil!
        number = self.preserve_x_amount_of_sigfig(number, @metadata.maximum_significant_figures.not_nil!)
      end

      return true, number.to_s
    end

    # Formats a number (given as string) based on the pattern set by the instance.
    #
    # ```
    # rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.###").parse
    # formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)
    #
    # formatter.format("12345")     # => 12,345
    # formatter.format("1000.1236") # => 1,000.124
    # ```
    def format(number : String)
      # The presence of minimum_significant_figures means that the pattern is a significant figure pattern
      if @metadata.minimum_significant_figures
        # If the amount of digits in number is greater than the maximum significant figures allowed,
        # we'll go ahead and around it down to that. Otherwise, we just confirm that the pattern is in fact a
        # significant figure pattern
        sig_pattern, number = self.round_significant(number.to_f)
        numerical_components = number.split "."
      else
        numerical_components = number.split "."
      end

      case numerical_components.size
      when 2 then integer, fractional = numerical_components
      when 1 then integer, fractional = numerical_components[0], ""
      else        raise LensExceptions::ParseError.new("Looks like I cannot parse the number: '#{number}'. " \
                                                "Maybe there's an extra decimal point?")
      end

      if negative = integer.starts_with? "-"
        integer = integer[1..]
      else
        negative = false
      end

      # Invalid number handling
      if integer.starts_with?("-") || fractional.starts_with?("-")
        raise ArgumentError.new("Invalid number: '#{number}' given to #format of PatternFormatter")
      end

      begin
        integer.to_i(prefix: false, whitespace: false)

        if !fractional.empty?
          fractional.to_i(prefix: false, whitespace: false)
        end
      rescue ArgumentError
        raise ArgumentError.new("Invalid number: '#{number}' given to #format of PatternFormatter")
      end

      return self.internal_format(integer, fractional, negative: negative, sig_pattern: sig_pattern)
    end

    # Formats a number based on the pattern set by the instance
    def format(number : Int)
      negative = number.negative?
      number = number.abs if negative

      # The presence of minimum_significant_figures means that the pattern is a significant figure pattern
      if @metadata.minimum_significant_figures
        # If the amount of digits in number is greater than the maximum significant figures allowed,
        # we'll go ahead and around it down to that. Otherwise, we just confirm that the pattern is in fact a
        # significant figure pattern
        sig_pattern, number = self.round_significant(number)
      else
        number = number.to_s
        sig_pattern = false
      end

      if negative
        return self.internal_format(number, "", negative: true, sig_pattern: sig_pattern)
      else
        return self.internal_format(number, "", sig_pattern: sig_pattern)
      end
    end

    # Formats a number based on the pattern set by the instance
    def format(number : Float)
      negative = number.negative?
      number = number.abs if negative

      # The presence of minimum_significant_figures means that the pattern is a significant figure pattern
      if @metadata.minimum_significant_figures
        # If the amount of digits in number is greater than the maximum significant figures allowed,
        # we'll go ahead and around it down to that. Otherwise, we just confirm that the pattern is in fact a
        # significant figure pattern
        sig_pattern, number = self.round_significant(number)
      else
        number = number.to_s
        sig_pattern = false
      end

      numerical_components = number.split "."

      case numerical_components.size
      when 2 then integer, fractional = numerical_components
      when 1 then integer, fractional = numerical_components[0], ""
      else        raise "Unreachable"
      end

      if negative
        return self.internal_format(integer, fractional, negative: true, sig_pattern: sig_pattern)
      else
        return self.internal_format(integer, fractional, sig_pattern: sig_pattern)
      end
    end

    # This is a reimplementation of #significant with some patches for accuracy,
    # and limited to only base 10.
    private def preserve_x_amount_of_sigfig(number, digits)
      if digits < 0
        raise ArgumentError.new "digits should be non-negative"
      end

      if number == 0
        return number.to_s
      end

      x = number.to_f

      log = Math.log10(number.abs)

      exponent = (log - digits + 1).floor

      if exponent < 0
        y = 10 ** -exponent
        value = (x * y).round / y
      else
        y = 10 ** exponent
        value = (x / y).round * y
      end

      value = value.to_s

      if value.ends_with?(".0")
        return value[...-2]
      end

      return value
    end

    # Count how many zeros appear in a row within an string. Direction corresponds to the
    # direction parameter, true equates to LTR while false means to RTL.
    private def count_zeros_of_string_encoded_number(string : String, direction : Bool)
      string = string.reverse if !direction
      count = 0
      string.each_char do |c|
        if c == '0'
          count += 1
        else
          break
        end
      end

      return count
    end
  end
end

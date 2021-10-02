module CLDR::Numbers
  # EXPERIMENTAL
  # TODO Write documentation
  class PatternFormatter(Lang)
    @instructions : PatternConstruct
    @metadata : Metadata
    @reader : Char::Reader

    def initialize(@instructions, @metadata)
      @reader = Char::Reader.new("") # Dummy
    end

    # Add X amount of integers to string from Int @reader.
    def add_number_to_str_x_times(str, @reader, times)
      times.times do
        char = @reader.current_char
        if char == '\0'
          return false
        end

        str << char
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
          status = self.add_number_to_str_x_times(io, @reader, primary.not_nil!)

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
        self.add_number_to_str_x_times(io, @reader, primary.not_nil!)

        # If there's still enough characters to *potentially* create a secondary group,
        # then we'll go ahead and add the marker.
        if (component_size - @reader.pos) != 0
          io << Lang::GroupSymbol
        end

        # Now we handle the second secondary
        while (component_size - @reader.pos) >= secondary
          status = self.add_number_to_str_x_times(io, @reader, secondary.not_nil!)
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

    private def add_remaining_characters_to_io(io)
      while @reader.current_char != '\0'
        io << @reader.current_char
        @reader.next_char
      end
    end

    private def normalize_fraction_size(fractional, rule : Rules::Fractional)
      # When the amount of fraction digits exceeds what the pattern allows
      # then we're do a half-even (ties_even) rounding to get it to the maximums
      # size the rule allows.
      if fractional.size > rule.size
        processed = "0.#{fractional}".to_f64.round(rule.size, mode: :ties_even).to_s[2..]

        # When the amount of fractional digits is less than the amount required by the rules we'll go ahead
        # and add trailing zeros
      elsif fractional.size < rule.size && rule.trailing_zeros
        processed = (fractional + "0" * (rule.size - fractional.size))
      else
        processed = fractional
      end

      return processed
    end

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
      numerical_components = number.split "."

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
        fractional.to_i(prefix: false, whitespace: false)
      rescue ArgumentError
        raise ArgumentError.new("Invalid number: '#{number}' given to #format of PatternFormatter")
      end

      return self.internal_format(integer, fractional, negative: negative)
    end

    # Formats a number based on the pattern set by the instance
    def format(number : Int)
      if number.negative?
        return self.internal_format(number.abs.to_s, "", negative: true)
      else
        return self.internal_format(number.to_s, "")
      end
    end

    # Formats a number based on the pattern set by the instance
    def format(number : Float)
      integer, fractional = number.abs.to_s.split "."

      if number.negative?
        return self.internal_format(integer, fractional, negative: true)
      else
        return self.internal_format(integer, fractional)
      end
    end

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

    private def internal_format(integer, fractional, negative = false)
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
      end

      formatted_suffix = self.format_affix(suffix)
      return "#{formatted_prefix}#{formatted_int.reverse}#{formatted_fractional}#{formatted_suffix}"
    end
  end
end

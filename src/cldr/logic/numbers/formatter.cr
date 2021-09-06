module CLDR::Numbers
  # EXPERIMENTAL
  # TODO Write documentation
  class PatternFormatter(Lang)
    @instructions : Array(Rules::Rules)
    @fractional_instructions : Array(Rules::Rules)
    @metadata : Metadata

    @integer : String
    @fractional : String

    def initialize(@instructions, @fractional_instructions, @metadata, number : String)
      # The formatted number shall be constructed in reverse
      numerical_components = number.split "."

      case numerical_components.size
      when 2 then @integer, @fractional = numerical_components
      when 1 then @integer, @fractional = numerical_components[0], ""
      else        raise LensExceptions::ParseError.new("Looks like I cannot parse the number: '#{number}'. " \
                                                "Maybe there's an extra decimal point?")
      end

      @integer_reader = Char::Reader.new(@integer.reverse)
    end

    def initialize(@instructions, @fractional_instructions, @metadata, number : Float64)
      # The formatted number shall be constructed in reverse
      @integer, @fractional = number.to_s.split "."
      @integer_reader = Char::Reader.new(@integer.reverse)
    end

    def initialize(@instructions, @fractional_instructions, @metadata, number : Int32)
      # The formatted number shall be constructed in reverse
      @fractional = ""
      @integer = number.to_s

      @integer_reader = Char::Reader.new(@integer.reverse)
    end

    # Add X amount of integers to string from Int reader.
    def add_integer_to_str_x_times(str, times)
      times.times do
        char = @integer_reader.current_char
        if char == '\0'
          return false
        end

        str << char
        @integer_reader.next_char
      end

      return true
    end

    # Handles the grouping of the integer numbers.
    #
    # CLDR defines two grouping types.
    # - Primary | Least significant digits
    # - Secondary | Everything else
    #
    # For most languages, they are the same size. However, some such as Hindi have
    # different values. Because of that, we need to handle both separately.
    #
    # Recall that during parsing, we did some special evaluations of these groups. Mainly:
    #
    # 1. When the primary_group is equal to the secondary_group, the secondary_group attribute
    # would be unset within @metadata and remain as nil.
    #
    # 2. Each *valid* and different group within the number pattern, results in
    # a different `Rules::Group`.
    #
    # This means that this method has three different paths:
    #
    # 1. To handle the case where there is only a primary group, as in all the integers
    # are split into chunks of primary grouping sizes.
    # 2. To handle the case of grouping the first  X (of primary grouping sizes) amount of
    # numbers and **only** the first X amount.
    # 3. Split leftover numbers into chunks of secondary grouping sizes.
    #
    private def handle_group(str)
      if !@metadata.secondary_grouping && (grouping = @metadata.primary_grouping)
        while (@integer.size - @integer_reader.pos) != 0
          status = self.add_integer_to_str_x_times(str, grouping)
          if !status
            break
          end

          # Check again that we're still able to group. If so, start the next portion with a marker.
          if (@integer.size - @integer_reader.pos) >= grouping
            str << Lang::GroupSymbol
          end
        end
      else
        # When there is a secondary group, then there must be a primary group. And since
        # the IO is empty, we know we're currently at the start (or right-most number in
        # the integer portion of the number). This means that we can handle the single
        # primary group we need to group successfully.
        if str.empty? && (grouping = @metadata.primary_grouping)
          self.add_integer_to_str_x_times(str, grouping)

          # If there's still enough characters to *potentially* create a secondary group,
          # then we'll go ahead and add the marker.
          if (@integer.size - @integer_reader.pos) != 0
            return str << Lang::GroupSymbol
          end
        else
          grouping = @metadata.secondary_grouping.not_nil!
          # We only group when the amount of characters left in the int reader is actually enough
          # to group.
          while (@integer.size - @integer_reader.pos) >= grouping
            status = self.add_integer_to_str_x_times(str, grouping)
            # It only returns false when we're at at the end of source.
            # TODO refactor variable name to be more intuitive.
            if !status
              break
            end

            # Check again that we're still able to group. If so, start the next portion with a marker.
            if (@integer.size - @integer_reader.pos) >= grouping
              str << Lang::GroupSymbol
            end
          end
        end
      end
    end

    def handle_fractional_group(str, rule : Rules::Fractional)
      # When the amount of fraction digits exceeds what the pattern allows
      # then we're do a half-even (ties_even) rounding to get it to the maximums
      # size the rule allows.
      if @fractional.size > rule.size
        str << "0.#{@fractional}".to_f64.round(rule.size, mode: :ties_even).to_s[2..]

        # When the amount of fractional digits is less than the amount required by the rules we'll go ahead
        # and add trailing zeros
      elsif @fractional.size < rule.size && rule.trailing_zeros
        str << (@fractional + "0" * (rule.size - @fractional.size))
      else
        str << @fractional
      end
    end

    def inject_symbol(str, rule : Rules::InjectSymbol)
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

    def format
      formatted_int = String.build do |str|
        @instructions.each do |rule|
          case rule
          when Rules::Group        then self.handle_group(str)
          when Rules::InjectSymbol then self.inject_symbol(str, rule)
          end
        end
      end

      formatted_fractional = String.build do |str|
        if @fractional.empty?
          break
        end
        @fractional_instructions.each do |rule|
          case rule
          when Rules::InjectSymbol then self.inject_symbol(str, rule)
          when Rules::Fractional   then self.handle_fractional_group(str, rule)
          end
        end
      end

      puts "#{formatted_int.reverse}#{formatted_fractional}"
    end
  end
end

module CLDR::Numbers
  class PatternFormatter(Lang)
    @instructions : Array(Rules::Rules)
    @fractional_instructions : Array(Rules::Rules)
    @metadata : Metadata

    @integer : String
    @fractional : String

    def initialize(@instructions, @fractional_instructions, @metadata, number : Int32 | Float64)
      # The formatted number shall be constructed in reverse
      @integer, @fractional = number.to_s.split "."

      @integer_reader = Char::Reader.new(@integer.reverse)
    end

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

    def handle_group(str)
      # Handle primary grouping
      if grouping = @metadata.primary_grouping
        # If the formatted number is currently empty and there is a
        # secondary grouping option then we'll only add the primary grouping
        # once. Here.
        if str.empty? && @metadata.secondary_grouping
          add_integer_to_str_x_times(str, grouping)
          str << Lang::GroupSymbol
          return
        elsif !@metadata.secondary_grouping
          while (@integer.size - @integer_reader.pos) != 0
            status = add_integer_to_str_x_times(str, grouping)
            if !status
              break
            end

            if (@integer.size - @integer_reader.pos) != 0
              str << Lang::GroupSymbol
            end
          end
        end
      end

      if grouping = @metadata.secondary_grouping
        # We only use secondary grouping if the amount of
        # integers left is greater than the grouping size
        chars_left = (@integer.size - @integer_reader.pos)

        while chars_left >= grouping
          status = add_integer_to_str_x_times(str, grouping)
          if !status
            break
          end

          if (@integer.size - @integer_reader.pos) != 0
            str << Lang::GroupSymbol
          end
        end
      end
    end

    def handle_fractional_group(str, rule : Rules::Fractional)
      if @fractional.size > rule.size
        str << "0.#{@fractional}".to_f64.round(rule.size, mode: :ties_even).to_s[2..]
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

module CLDR::Numbers
  private module Rules
    abstract struct Rules
    end

    struct InjectSymbol < Rules
      getter character

      def initialize(@character : TokenTypes)
      end
    end

    struct InjectCharacters < Rules
      getter character

      def initialize(@character : String)
      end
    end

    struct Integer < Rules
      # Same as forbidden_trailing_zero_range in `Fractional` but for leading zeros.
      getter forbidden_leading_zero_count

      def initialize(@forbidden_leading_zero_count : Int32)
      end
    end

    struct Fractional < Rules
      # Amount of forbidden trailing zeros at the end of the fractional portion of the formatted number.
      #
      # This is best explained by example:
      # Pattern: '0.000####' has a maximum fraction size of 7 characters and forbids 4 trailing zeros
      #   Number: 0.123 results in this **internally*: '0.1230000' due to trailing zero padding but
      #   since we forbid 4 trailing zeros, the actual formatted number is '0.123'
      #   Number: 0.1234 -> 0.1234
      #
      # Since we allow for intermediate #s within a pattern, we forbid 3 trailing zeros.+
      # Pattern: '0.000###0000
      # Number: 0.1 -> 0.1000000
      #
      getter forbidden_trailing_zero_count
      getter size

      def initialize(@forbidden_trailing_zero_count : Int32, @size : Int32)
      end
    end
  end

  private class Metadata
    {% for method in %w(setter getter) %}
      {{method.id}} secondary_grouping : Int32?
      {{method.id}} primary_grouping : Int32?

      {{method.id}} fractional_secondary_grouping : Int32?
      {{method.id}} fractional_primary_grouping : Int32?

      {{method.id}} maximum_significant_figures : Int32?
      {{method.id}} minimum_significant_figures : Int32?

      {{method.id}} use_padding : Bool
      {{method.id}} padding_character : String?



    {% end %}

    def initialize
      @secondary_grouping = nil
      @primary_grouping = nil
      @fractional_secondary_grouping = nil
      @fractional_primary_grouping = nil
      @maximum_significant_figures = nil
      @minimum_significant_figures = nil
      @use_padding = false
      @padding_character = nil
    end
  end
end

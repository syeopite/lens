module CLDR::Numbers
  private module Rules
    abstract struct Rules
    end

    struct InjectSymbol < Rules
      getter character

      def initialize(@character : TokenTypes)
      end
    end

    {% for name in %w(Group Fractional) %}
      struct {{name.id}} < Rules
        getter leading_zeros
        getter trailing_zeros
        getter size

        def initialize(@leading_zeros : Bool, @trailing_zeros : Bool, @size : Int32)
        end
      end
    {% end %}
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

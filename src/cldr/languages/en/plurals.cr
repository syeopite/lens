require "../language"

module CLDR
  module Languages
    module EN
      def self.cardinal_plural(number : Int32 | Int64 | Float64)
        n = CLDR::Plurals.get_n(number)
        if n == 1
          return :one
        else
          return :other
        end
      end
    end
  end
end

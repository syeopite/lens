module CLDR
  module Plurals
    alias Number = Int32 | Int64 | Float64

    # Computes and returns all the CLDR properties regarding a number
    def self.compute_number_properties(source)
      n = source.abs
      # When source is an int then everything besides n and i would be 0
      if source.is_a? Int
        return n, n, 0, 0, 0, 0
      end

      i = n.to_i
      f = n.to_s.split(".")[1]
      v = f.size

      # #rstrip removes all zeros but we only need the ones after
      # the first zero removed
      t = f.rstrip('0')
      t = t.empty? ? 0 : t.to_i

      w = f.rstrip('0')
      w = w.empty? ? 0 : w.size

      return n, i, v, w, f.to_i, t
    end

    # Get CLDR plural operand `n`, absolute value of the source number.
    def self.get_n(source : Number) : Number
      # Strip leading ns
      return source.abs
    end

    # Same as `get_n(source : Number)` but for String
    def self.get_n(source : String) : Number
      result = get_abs_string(source)

      if result.includes? "."
        result.rstrip('0')
        return 0 if result.empty?
      end

      return result.includes?(".") ? result.to_f : result.to_i
    end

    # Get CLDR plural operand `i`, integer digits of n.
    def self.get_i(source : Number) : Int
      return source.abs.to_i
    end

    # Same as `get_i(source : Number)` but for String
    def self.get_i(source : String) : Int
      return get_abs_string(source).split(".")[0].to_i
    end

    # Get CLDR plural operand `v`, number of visible fraction digits in n, with trailing zeros.
    def self.get_v(source : Number) : Int
      if !source.is_a? Float
        return 0
      end

      v = source.abs.to_s.split(".")[1]
      v = v.empty? ? 0 : v.size

      return v
    end

    # Same as `get_v(source : Number)` but for String
    def self.get_v(source : String) : Int
      if !source.includes? "."
        return 0
      else
        return get_abs_string(source).split(".")[1].size
      end
    end

    # Get CLDR plural operand `w`, number of visible fraction digits in n, without trailing zeros.
    def self.get_w(source : Number) : Int
      if !source.is_a? Float
        return 0
      end

      w = source.abs.to_s.split(".")[1].rstrip('0')
      w = w.empty? ? 0 : w.size

      return w
    end

    # Same as `get_w(source : Number)` but for String
    def self.get_w(source : String) : Int
      if !source.includes? "."
        return 0
      end

      w = get_abs_string(source).split(".")[1].rstrip('0')
      w = w.empty? ? 0 : w.size

      return w
    end

    # Get CLDR plural operand `f`, visible fraction digits in n, with trailing zeros.
    def self.get_f(source : Number) : Int
      if !source.is_a? Float
        return 0
      end

      return source.abs.to_s.split(".")[1].to_i
    end

    # Same as `get_f(source : Number)` but for String
    def self.get_f(source : String) : Int
      if !source.includes? "."
        return 0
      end

      return get_abs_string(source).split(".")[1].to_i
    end

    # Get CLDR plural operand `t`, visible fraction digits in n, without trailing zeros.
    def self.get_t(source : Number) : Int
      if !source.is_a? Float
        return 0
      end

      t = source.abs.to_s.split(".")[1].rstrip('0')
      t = t.empty? ? 0 : t.to_i

      return t
    end

    # Same as `get_t(source : Number)` but for String
    def self.get_t(source : String) : Int
      if !source.includes? "."
        return 0
      end

      t = get_abs_string(source).split(".")[1].rstrip('0')
      t = t.empty? ? 0 : t.to_i

      return t
    end

    private def self.get_abs_string(source : String)
      return source.starts_with?("-") ? source[1..] : source
    end
  end
end

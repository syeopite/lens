# :nodoc:
module YAML
  struct Any
    # dig method overload to support using arrays for subkeys
    def dig(index_or_key, subkeys : Array)
      if subkeys.empty?
        return self[index_or_key]
      else
        first_subkey = subkeys.shift
        return self[index_or_key].dig(first_subkey, subkeys)
      end
    end
  end
end

# :nodoc:
class Hash
  # dig method overload to support using arrays for subkeys
  def dig(key, subkeys : Array)
    if (value = self[key]) && value.responds_to?(:dig)
      first_subkey = subkeys.shift
      return value.dig(first_subkey, subkeys)
    end
    raise KeyError.new "Hash value not diggable for key: #{key.inspect}"
  end
end

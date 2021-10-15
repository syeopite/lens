# :nodoc:
# Work around for crystal-lang/crystal#10888
def modulo(a, b)
  if a.is_a? Int && b.is_a? Int
    return a % b
  elsif a.is_a? Float && b.is_a? Float
    return a % b
  else
    return a.to_f % b.to_f
  end
end

# :nodoc:
# Count how many zeros appear in a row within an string. Direction corresponds to the
# direction parameter, true equates to LTR while false means to RTL.
def count_zeros_of_string_encoded_number(string : String, direction : Bool)
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

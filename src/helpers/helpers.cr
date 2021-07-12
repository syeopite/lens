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

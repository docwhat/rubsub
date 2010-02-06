# Monkey patch String to add a starts_with? method.
class String
  if not method_defined? "starts_with?"
    def starts_with?(prefix)
      prefix = prefix.to_s
      self[0, prefix.length] == prefix
    end
  end
end


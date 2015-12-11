class Regexp
  def self.identifier
    /(?:(?!true|false))\b([a-zA-Z_][a-zA-Z0-9_]*)\b/
  end
end
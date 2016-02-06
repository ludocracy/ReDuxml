require_relative '../ext/regexp'
require_relative '../ext/string'

class Macro < String
  def initialize str
    s = (str[0,1] == '@') ? str : "@(#{str})"
    super s
  end

  def demacro
    self[2..-2]
  end

  def parameterized?
    match Regexp.identifier
  end
end
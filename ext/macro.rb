require File.expand_path(File.dirname(__FILE__) +  '/../../Dux/ext/regexp')
require File.expand_path(File.dirname(__FILE__) +  '/string')

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
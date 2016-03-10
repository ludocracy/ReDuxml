require File.expand_path(File.dirname(__FILE__) +  '/../../Dux/ext/string')

class String
  def parameterized?
    self.include?('@(')
  end
end
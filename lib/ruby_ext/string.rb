require File.expand_path(File.dirname(__FILE__) +  '/../../../Dux/lib/dux/ruby_ext/string')

class String
  # returns whether or not contents include any Macro strings i.e. Parameter expressions
  def parameterized?
    self.include?('@(')
  end
end
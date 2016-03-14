require File.expand_path(File.dirname(__FILE__) +  '/../../../Dux/lib/dux/ruby_ext/string')

class String
  def parameterized?
    self.include?('@(')
  end
end
require 'duxml'

class Regexp
  # @return [Regexp] single and double quoted strings
  def self.string
    /['"][^'"]*['"]/
  end
end
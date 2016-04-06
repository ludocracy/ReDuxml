require File.expand_path(File.dirname(__FILE__) +  '/../../../Dux/lib/dux/ruby_ext/regexp')
require File.expand_path(File.dirname(__FILE__) +  '/string')

# string wrapped in parameter expression macro symbol and delimiters,
# indicating content is to be parsed and resolved when building and validating XML design
class Macro < String
  MACRO_SYMBOL = '@'
  DELIMITERS = %w{( )}
  # takes given string and wraps in Macro symbol and delimiters if not already wrapped
  # e.g. str => 'asdf'
  #      Macro.new str => '@(asdf)'
  def initialize(str)
    s = (str[0,1] == MACRO_SYMBOL) ? str : "#{MACRO_SYMBOL}#{DELIMITERS.first}#{str}#{DELIMITERS.last}"
    super s
  end

  # returns string without macro symbol and delimiters
  def demacro
    self[2..-2]
  end

  # returns nil if not, and match data for any parameter names found
  def parameterized?
    match Regexp.identifier
  end
end
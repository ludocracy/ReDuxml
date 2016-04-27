require_relative 'string'

# string wrapped in parameter expression macro symbol and delimiters,
# indicating content is to be parsed and resolved when building and validating XML design
class Macro
  include Enumerable
  include Comparable

  # is '@' by default
  MACRO_SYMBOL = '@'
  # are parentheses by default e.g. '()'
  DELIMITERS = %w{( )}

  @macro_string

  # string including MACRO_SYMBOL and DELIMITERS
  attr_accessor :macro_string

  # takes given string and wraps in MACRO_SYMBOL and DELIMITERS if not already wrapped
  # e.g. str => 'asdf'
  #      Macro.new str => '@(asdf)'
  def initialize(str)
    @macro_string = is_macro?(str) ? str : "#{MACRO_SYMBOL}#{DELIMITERS.first}#{str}#{DELIMITERS.last}"
  end

  # checks a string to see if it's a valid macro expression without leading or trailing non-expression or delimiter text
  def is_macro?(str)
    str[0,2] == MACRO_SYMBOL+DELIMITERS.first && str[-1] == DELIMITERS.last && str.balanced_parens?
  end

  # compares #demacro'd @macro_string to obj
  def <=>(obj)
    demacro <=> obj
  end

  # just yields each character of #demacro'd @macro_string
  def each(&block)
    demacro.split(//).each do |char| yield char end
  end

  # returns string without MACRO_SYMBOL and DELIMITERS
  def demacro
    macro_string[2..-2]
  end

  # returns nil if not, and match data for any parameter names found
  def parameterized?
    macro_string.match Regexp.identifier
  end
end # class Macro
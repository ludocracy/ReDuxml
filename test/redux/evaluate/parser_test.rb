require_relative '../../../lib/re_dux/evaluate/parser'
require 'test/unit'

class MacroParserTest < Test::Unit::TestCase
  include Parser

  def test_lexer
    ts = lex('9 < 7').collect do |t| t.type end
    assert_equal [:num, :operator, :num], ts
    ts = lex('9 < var').collect do |t| t.type end
    assert_equal [:num, :operator, :param], ts
    ts = lex('"s s " != var').collect do |t| t.type end
    vs = lex('"s s " != var').collect do |t| t.value end
    assert_equal [:string, :operator, :param], ts
    assert_equal ['"s s "', '!=', 'var'], vs
    ts = lex('var ? true : 0').collect do |t| t.type end
    assert_equal [:param, :operator, :bool, :operator, :num], ts
  end

  def test_parse
    # unary
    lex('-')
    # binary
    # ternary
    # OoO-reversed

    # OoO-reverse_grouped
  end
end
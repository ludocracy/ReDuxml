require_relative '../../../lib/re_dux/evaluate/parser'
require 'test/unit'

class MacroParserTest < Test::Unit::TestCase
  include ReDuxml

  def setup
    @p = Parser.new File.expand_path(File.dirname(__FILE__) + '/../../../xml/logic.xml')
  end

  attr_reader :p

  def test_lexer
    ts = p.lex('9 < 7').collect do |t| t.type end
    assert_equal [:num, :operator, :num], ts
    ts = p.lex('9 < var').collect do |t| t.type end
    assert_equal [:num, :operator, :param], ts
    tokens = p.lex('-9-7 - var')
    o = p.get_op(tokens.first)
    ts = p.lex('-9-7 - var').collect do |t| t.type == :operator ? p.get_op(t).id : t.type.to_s end
    assert_equal %w(neg num sub num sub param), ts
    # TODO test re-substitution of strings here!
    ts = p.lex('"s s " != var').collect do |t| t.type end
    vs = p.lex('"s s " != var').collect do |t| t.value end
    assert_equal [:string, :operator, :param], ts
    assert_equal ['"s s "', '!=', 'var'], vs
    ts = p.lex('var ? true : 0').collect do |t| t.type end
    assert_equal [:param, :operator, :bool, :grouping, :num], ts
  end

  def test_parse
    # unary
    ast = p.parse '!true'
    assert_equal "(!\n  (true))", ast.to_sexp

    # binary
    ast = p.parse '2 + 2'
    assert_equal "(+\n  (2)\n  (2))", ast.to_sexp

    # ternary
    ast = p.parse 'var ? "true!!!" : 3'
    output = ast.to_sexp
    assert_equal %((?\n  (var)\n  ("true!!!")\n  (3))), output

    # OoO-reversed
    ast = p.parse 'var - 2 * 6'
    output = ast.to_sexp
    assert_equal %((\u2013\n  (var)\n  (*\n    (2)\n    (6)))), output

    # OoO-reverse_grouped
    ast = p.parse '(var - 2) * 6'
    output = ast.to_sexp
    assert_equal %((*\n  (\u2013\n    (var)\n    (2))\n  (6))), output
  end
end
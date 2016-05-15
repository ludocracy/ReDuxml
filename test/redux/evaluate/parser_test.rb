require_relative '../../../lib/re_dux/evaluate/parser'
require 'test/unit'

class ParserTest < Test::Unit::TestCase
  include ReDuxml

  def setup
    @p = Parser.new File.expand_path(File.dirname(__FILE__) + '/../../../xml/logic.xml')
  end

  attr_reader :p

  def test_parse_groups
    # unary
    ast = p.parse '!true'
    assert_equal "(!\n  (true))", ast.to_sexp
    assert_equal :prefix, ast.type.position

    # binary
    ast = p.parse '2 + 2'
    assert_equal "(+\n  (2)\n  (2))", ast.to_sexp
    ast = p.parse 'var0 == var1'
    assert_equal '!=', ast.type.inverse.symbol

    # binary, associative
    ast = p.parse '2**var'
    assert_equal '2**var', ast.print

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

  def test_ternary_nested
    ast = p.parse 'true ? true ? 0 : 1 : 2'
    assert_equal "(?\n  (true)\n  (?\n    (true)\n    (0)\n    (1))\n  (2))", ast.to_sexp
  end

  def test_parse_types
    ast = p.parse 'var + 2'
    assert_equal '(var)', ast.children.first.to_s
    assert_equal 'Symbolic::Variable', ast.children.first.type.class.to_s
    assert_equal 2, ast.children.last.type
  end
end
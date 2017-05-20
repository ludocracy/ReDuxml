require_relative '../../../lib/re_duxml/evaluate/parser'
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
    assert_equal '!', ast.type.symbol
    assert_equal '[s(:true)]', ast.children.to_s
    assert_equal :prefix, ast.type.position

    # binary
    ast = p.parse '2 + 2'
    assert_equal '+', ast.type.symbol
    assert_equal '[s(:2), s(:2)]', ast.children.to_s
    ast = p.parse 'var0 == var1'
    assert_equal '!=', ast.type.inverse.symbol

    # binary, associative
    ast = p.parse '2**var'
    assert_equal '2**var', ast.print

    # ternary
    ast = p.parse 'var ? "true!!!" : 3'
    assert_equal '?', ast.type.symbol
    assert_equal '[s(:var), s(:"true!!!"), s(:3)]', ast.children.to_s

    # OoO-reversed
    ast = p.parse 'var + 2 * 6'
    output = ast.print
    assert_equal 'var+2*6', output

    # OoO-reverse_grouped
    ast = p.parse '(var + 2) * 6'
    assert_equal '*', ast.type.symbol
    assert_equal '(6)', ast.children.last.to_s
    assert_equal '+', ast.children.first.type.symbol
    assert_equal '[s(:var), s(:2)]', ast.children.first.children.to_s
  end

  def test_ternary_nested
    ast = p.parse 'true ? true ? 0 : 1 : 2'
    assert_equal '?', ast.type.symbol
    assert_equal '(true)', ast.children.first.to_s
    sub_ast = ast.children[1]
    assert_equal '?', sub_ast.type.symbol
    assert_equal '(2)', ast.children[2].to_s
    assert_equal '[s(:true), s(:0), s(:1)]', sub_ast.children.to_s
  end

  def test_parse_types
    ast = p.parse 'var + 2'
    assert_equal '(var)', ast.children.first.to_s
    assert_equal 'Symbolic::Variable', ast.children.first.type.class.to_s
    assert_equal 2, ast.children.last.type
  end
end
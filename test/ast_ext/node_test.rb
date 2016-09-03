require_relative '../../lib/ast_ext/node'
require_relative '../../lib/re_duxml/evaluate/parser'

require 'test/unit'

class NodeTest < Test::Unit::TestCase
  include AST

  def setup
    @p = ReDuxml::Parser.new('../../xml/logic.xml')
  end

  attr_reader :p

  def test_initialize_non_symbol_type
    n = AST::Node.new(9)
    assert_equal 9, n.type
  end

  def test_print
    #unary
    unary = p.parse '!true'
    assert_equal '!true', unary.print

    #binary
    unary = p.parse 'var % 4'
    assert_equal 'var%4', unary.print

    #ternary
    unary = p.parse 'var ? 5 : "asdf"'
    assert_equal 'var?5:"asdf"', unary.print
  end
end
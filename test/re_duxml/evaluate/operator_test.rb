require_relative '../../../lib/re_duxml/evaluate/operator'
require 'duxml'
require 'test/unit'

include Operator

class OperatorTest < Test::Unit::TestCase
  include Duxml

  def setup
    load File.expand_path(File.dirname(__FILE__) + '/../../../xml/logic.xml')
  end

  def test_operator_loading
    ops = doc.root.Operator()
    assert_equal false, ops.last.right_associative?
    assert_equal true, ops[-6].right_associative?
    assert_equal :prefix, ops.last.position
    assert_equal :infix, ops[-5].position
    assert_equal 'mul', ops[-5].id
    assert_equal '*', ops[-5].ruby
    assert_equal '**', ops[-2].ruby
    assert_equal '60', ops[-5].precedence
    assert_equal /\*/, ops[-5].regexp
    assert_equal '*', ops[-5].symbol
    assert_equal 2, ops[-5].arity
    assert_equal 1, ops[-6].arity
    assert_equal 'log', ops.last.symbol
    assert_equal '&&', ops[6].symbol
  end
end
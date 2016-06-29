require_relative '../../../lib/symbolic_ext/variable'
require 'test/unit'

class VariableTest < Test::Unit::TestCase
  def test_compare
    foo = var(name: 'foo')
    bar = var(name: 'bar')
    assert_equal true, foo == foo
    assert_equal false, foo != foo
    assert_equal true, foo <= foo
    assert_equal true, foo >= foo
    assert_equal false, foo > foo
    assert_equal false, foo < foo
    assert_equal nil, (foo == bar)
    assert_equal nil, (foo != bar)
    assert_equal nil, (foo <= bar)
    assert_equal nil, (foo >= bar)
    assert_equal nil, (foo > bar)
    assert_equal nil, (foo < bar)
    assert_equal nil, (foo == 1)
    assert_equal nil, (foo != 1)
    assert_equal nil, (foo <= 1)
    assert_equal nil, (foo >= 1)
    assert_equal nil, (foo > 1)
    assert_equal nil, (foo < 1)
  end
end
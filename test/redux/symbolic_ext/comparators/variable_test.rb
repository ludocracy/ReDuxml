require_relative '../../../../lib/symbolic_ext/comparators/variable'
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
    assert_equal "(==\n  (foo)\n  (bar))", (foo == bar).to_sexp
    assert_equal "(!=\n  (foo)\n  (bar))", (foo != bar).to_sexp
    assert_equal "(<=\n  (foo)\n  (bar))", (foo <= bar).to_sexp
    assert_equal "(>=\n  (foo)\n  (bar))", (foo >= bar).to_sexp
    assert_equal "(>\n  (foo)\n  (bar))", (foo > bar).to_sexp
    assert_equal "(<\n  (foo)\n  (bar))", (foo < bar).to_sexp
    assert_equal "(==\n  (foo)\n  (1))", (foo == 1).to_sexp
    assert_equal "(!=\n  (foo)\n  (1))", (foo != 1).to_sexp
    assert_equal "(<=\n  (foo)\n  (1))", (foo <= 1).to_sexp
    assert_equal "(>=\n  (foo)\n  (1))", (foo >= 1).to_sexp
    assert_equal "(>\n  (foo)\n  (1))", (foo > 1).to_sexp
    assert_equal "(<\n  (foo)\n  (1))", (foo < 1).to_sexp
  end
end
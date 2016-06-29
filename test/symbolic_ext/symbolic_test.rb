require_relative '../../../lib/symbolic_ext/symbolic'
require 'test/unit'

class SymbolicTest < Test::Unit::TestCase
  def test_modulus
    foo = var(name: 'foo')
    bar = var(name: 'bar')
    assert_equal 0, foo%foo
    assert_equal "(%\n  (foo)\n  (bar))", (foo%bar).to_sexp
    assert_equal "(%\n  (foo)\n  (2))", (foo%2).to_sexp
    assert_equal "(%\n  (2)\n  (bar))", (2%bar).to_sexp
  end
end
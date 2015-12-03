require_relative '../symja'
require 'minitest/autorun'

# tests answer validity
class SymjaTest < MiniTest::Test
  include Symja

  def setup
  end
  
  def test_boolean
    assert_equal "var", evaluate("var && true")
    assert_equal "False", evaluate("var && false")
    assert_equal "var", evaluate("true && var")
    assert_equal "False", evaluate("false && var")
    assert_equal "True", evaluate("var || true")
    assert_equal "var", evaluate("var || false")
    assert_equal "True", evaluate("true || var")
    assert_equal "var", evaluate("false || var")
    assert_equal "var", evaluate("var && var")
    assert_equal "var", evaluate("var || var")
    assert_equal "var", evaluate("var && true || false")
    assert_equal "var0 && var1", evaluate("var0 && var1")
    assert_equal "var1", evaluate("var0 && false || var1")
    assert_equal "var0", evaluate("var0 && (false || var0)")
    assert_equal "var0 && var1", evaluate("var0 && (false || var1)")
    assert_equal "!var", evaluate("!var")
    assert_equal "var", evaluate("!!var")
    assert_equal "!var", evaluate("!!!var")
    assert_equal "var1", evaluate("!var0 && var0 || var1")
  end # end of test_arithmetic


  def test_rational_preference
    assert_equal "1/2", e.evaluate("1/2")
    assert_equal "var/2", e.evaluate("var/2")
    assert_equal "1/var", e.evaluate("1/var")
    puts "test_rational_preference passed"
  end

  def test_arithmetic
    assert_equal "var", evaluate("var")
    assert_equal "4", evaluate("2+2")
    assert_equal "4", evaluate("2*2")
    assert_equal "2+var", evaluate("var+2")
    assert_equal "2*var", evaluate("var*2")
    assert_equal "var/2", evaluate("var/2")
    assert_equal "2/var", evaluate("2/var")
    assert_equal "2+var", evaluate("var+4-2")
    assert_equal "2*var", evaluate("var+var")
    assert_equal "var^2", evaluate("var*var")
    assert_equal "1", evaluate("var/var")
    assert_equal "2*var-1", evaluate("var*2-1")
    assert_equal "var-2", evaluate("var-2*1")
    assert_equal "2-var", evaluate("2-1*var")
    assert_equal "-(1/var)+2", evaluate("2-1/var")
    assert_equal "2*var", evaluate("var*2/1")
    assert_equal "0.5*var-1", evaluate("var/2-1")
    assert_equal "2*var", evaluate("2/1*var")
    assert_equal "2-var", evaluate("2/1-var")
    assert_equal "2*var", evaluate("var/2*4")
    assert_equal "2*var", evaluate("var*4/2")
    assert_equal "2*var-2", evaluate("var-2+var")
    assert_equal "-var", evaluate("var-2*var")
    assert_equal "var", evaluate("var*2-var")
    assert_equal "1.5*var", evaluate("var/2+var")
    assert_equal "2*var+2", evaluate("var-2+4+var")
    assert_equal "-7*var", evaluate("var-2*4*var")
    assert_equal "3*var", evaluate("var/2*4+var")
    assert_equal "3*var+1", evaluate("1+var/2*4+var")
  end # end of test_arithmetic

  def test_comparisons
    assert_equal "True", evaluate("2 == 2")
    assert_equal "True", evaluate("2 != 1")
    assert_equal "True", evaluate("2 < 4")
    assert_equal "False", evaluate("4 < 2")
    assert_equal "var == 4", evaluate("var == 4")
    assert_equal "var == 4", evaluate("4 == var")
    assert_equal "True", evaluate("var == var")
    assert_equal "False", evaluate("var != var")
    assert_equal "False", evaluate("!var == var")
    assert_equal "var0 == var1", evaluate("var0 == var1")
    assert_equal "var <= 4", evaluate("var <= 4")
    assert_equal "var < 4", evaluate("4 > var")
    assert_equal "True", evaluate("var >= var")
    assert_equal "False", evaluate("var < var")
  end # end of test_comparisons

  def tear_down
  end

end # Symjatest
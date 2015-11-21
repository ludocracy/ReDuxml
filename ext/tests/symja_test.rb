require_relative '../symja'
require 'minitest/autorun'

# tests answer validity
class SymjaTest < MiniTest::Test
  def setup
  end
    
  def test_regression
    assert_equal "true", Symja.evaluate("!var == !var")
    assert_equal "true", Symja.evaluate("var != !var")
  end
  
  def test_boolean
    assert_equal "var", Symja.evaluate("var && true")
    assert_equal "false", Symja.evaluate("var && false")
    assert_equal "var", Symja.evaluate("true && var")
    assert_equal "false", Symja.evaluate("false && var")
    assert_equal "true", Symja.evaluate("var || true")
    assert_equal "var", Symja.evaluate("var || false")
    assert_equal "true", Symja.evaluate("true || var")
    assert_equal "var", Symja.evaluate("false || var")
    assert_equal "var", Symja.evaluate("var && var")
    assert_equal "var", Symja.evaluate("var || var")
    assert_equal "var", Symja.evaluate("var && true || false")
    assert_equal "var0 && var1", Symja.evaluate("var0 && var1")
    assert_equal "var1", Symja.evaluate("var0 && false || var1")
    assert_equal "var0", Symja.evaluate("var0 && (false || var0)")
    assert_equal "var0 && var1", Symja.evaluate("var0 && (false || var1)")
    assert_equal "!var", Symja.evaluate("!var")
    assert_equal "var", Symja.evaluate("!!var")
    assert_equal "!var", Symja.evaluate("!!!var")
    assert_equal "var1", Symja.evaluate("!var0 && var0 || var1")
  end
  
  def test_arithmetic
    assert_equal "var", Symja.evaluate("var")
    assert_equal "4", Symja.evaluate("2+2")
    assert_equal "4", Symja.evaluate("2*2")
    assert_equal "2+var", Symja.evaluate("var+2")
    assert_equal "2*var", Symja.evaluate("var*2")
    assert_equal "0.5*var", Symja.evaluate("var/2")
    assert_equal "2/var", Symja.evaluate("2/var")
    assert_equal "2+var", Symja.evaluate("var+4-2")
    assert_equal "2*var", Symja.evaluate("var+var")
    assert_equal "var^2", Symja.evaluate("var*var")
    assert_equal "1", Symja.evaluate("var/var")
    assert_equal "2*var-1", Symja.evaluate("var*2-1")
    assert_equal "var-2", Symja.evaluate("var-2*1")
    assert_equal "2-var", Symja.evaluate("2-1*var")
    assert_equal "-(1/var)+2", Symja.evaluate("2-1/var")
    assert_equal "2*var", Symja.evaluate("var*2/1")
    assert_equal "0.5*var-1", Symja.evaluate("var/2-1")
    assert_equal "2*var", Symja.evaluate("2/1*var")
    assert_equal "2-var", Symja.evaluate("2/1-var")
    assert_equal "2*var", Symja.evaluate("var/2*4")
    assert_equal "2*var", Symja.evaluate("var*4/2")
    assert_equal "2*var-2", Symja.evaluate("var-2+var")
    assert_equal "-var", Symja.evaluate("var-2*var")
    assert_equal "var", Symja.evaluate("var*2-var")
    assert_equal "1.5*var", Symja.evaluate("var/2+var")
    assert_equal "2*var+2", Symja.evaluate("var-2+4+var")
    assert_equal "-7*var", Symja.evaluate("var-2*4*var")
    assert_equal "3*var", Symja.evaluate("var/2*4+var")
    assert_equal "3*var+1", Symja.evaluate("1+var/2*4+var")
  end

  def test_comparisons
    assert_equal "true", Symja.evaluate("2 == 2")
    assert_equal "true", Symja.evaluate("2 != 1")
    assert_equal "true", Symja.evaluate("2 < 4")
    assert_equal "false", Symja.evaluate("4 < 2")
    assert_equal "var == 4", Symja.evaluate("var == 4")
    assert_equal "var == 4", Symja.evaluate("4 == var")
    assert_equal "true", Symja.evaluate("var == var")
    assert_equal "false", Symja.evaluate("var != var")
    assert_equal "false", Symja.evaluate("!var == var")
    assert_equal "var0 == var1", Symja.evaluate("var0 == var1")
    assert_equal "var <= 4", Symja.evaluate("var <= 4")
    assert_equal "var < 4", Symja.evaluate("4 > var")
    assert_equal "true", Symja.evaluate("var >= var")
    assert_equal "false", Symja.evaluate("var < var")
  end
  
  def test_ternary
    assert_equal "var", Symja.evaluate("var ? true : false")
    assert_equal "var", Symja.evaluate("true ? var : false")
    assert_equal "var", Symja.evaluate("false ? true : var")
    assert_equal "var ? var0 : 1", Symja.evaluate("var ? var0 : 1")
  end

  def tear_down
  end
end

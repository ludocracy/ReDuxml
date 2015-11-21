require_relative '../ext/ruby'
require 'minitest/autorun'

class ParseTest < MiniTest::Test
  def setup
  end
    
  def test_regression
    assert_equal "true", "!var == !var".evaluate 
    assert_equal "true", "var != !var".evaluate 
  end
  
  def test_boolean
    assert_equal "var", "var && true".evaluate 
    assert_equal "false", "var && false".evaluate 
    assert_equal "var", "true && var".evaluate 
    assert_equal "false", "false && var".evaluate
    assert_equal "true", "var || true".evaluate 
    assert_equal "var", "var || false".evaluate 
    assert_equal "true", "true || var".evaluate 
    assert_equal "var", "false || var".evaluate 
    assert_equal "var", "var && var".evaluate 
    assert_equal "var", "var || var".evaluate 
    assert_equal "var", "var && true || false".evaluate 
    assert_equal "var0 && var1", "var0 && var1".evaluate 
    assert_equal "var1", "var0 && false || var1".evaluate 
    assert_equal "var0", "var0 && (false || var0)".evaluate 
    assert_equal "var0 && var1", "var0 && (false || var1)".evaluate 
    assert_equal "!var", "!var".evaluate 
    assert_equal "var", "!!var".evaluate 
    assert_equal "!var", "!!!var".evaluate 
    assert_equal "var1", "!var0 && var0 || var1".evaluate 
  end
  
  def test_arithmetic
    assert_equal "var", "var".evaluate 
    assert_equal "4", "2+2".evaluate  
    assert_equal "4", "2*2".evaluate  
    assert_equal "var+2", "var+2".evaluate  
    assert_equal "2*var", "var*2".evaluate  
    assert_equal "0.5*var", "var/2".evaluate  
    assert_equal "2/var", "2/var".evaluate  
    assert_equal "var+2", "var+4-2".evaluate  
    assert_equal "var+var", "var+var".evaluate  
    assert_equal "var*var", "var*var".evaluate  
    assert_equal "var/var", "var/var".evaluate  
    assert_equal "2*var-1", "var*2-1".evaluate  
    assert_equal "var-2", "var-2*1".evaluate  
    assert_equal "-var+2", "2-1*var".evaluate  
    assert_equal "-(1/var)+2", "2-1/var".evaluate 
    assert_equal "2*var", "var*2/1".evaluate  
    assert_equal "0.5*var-1", "var/2-1".evaluate  
    assert_equal "2*var", "2/1*var".evaluate  
    assert_equal "-var+2", "2/1-var".evaluate 
    assert_equal "2*var", "var/2*4".evaluate 
    assert_equal "2*var", "var*4/2".evaluate 
    assert_equal "var+var-2", "var-2+var".evaluate  
    assert_equal "var-2*var", "var-2*var".evaluate  
    assert_equal "2*var-var", "var*2-var".evaluate  
    assert_equal "0.5*var+var", "var/2+var".evaluate 
    assert_equal "var+var+2", "var-2+4+var".evaluate  
    assert_equal "var-8*var", "var-2*4*var".evaluate  
    assert_equal "2*var+var", "var/2*4+var".evaluate  
    assert_equal "2*var+var+1", "1+var/2*4+var".evaluate  
  end

  def test_comparisons
    assert_equal "true", "2 == 2".evaluate 
    assert_equal "true", "2 != 1".evaluate
    assert_equal "true", "2 < 4".evaluate 
    assert_equal "false", "4 < 2".evaluate 
    assert_equal "var == 4", "var == 4".evaluate 
    assert_equal "var == 4", "4 == var".evaluate 
    assert_equal "true", "var == var".evaluate 
    assert_equal "false", "var != var".evaluate 
    assert_equal "false", "!var == var".evaluate 
    assert_equal "var0 == var1", "var0 == var1".evaluate 
    assert_equal "var <= 4", "var <= 4".evaluate 
    assert_equal "var < 4", "4 > var".evaluate 
    assert_equal "true", "var >= var".evaluate 
    assert_equal "false", "var < var".evaluate 
  end
  
  def test_ternary
    assert_equal "var", "var ? true : false".evaluate 
    assert_equal "var", "true ? var : false".evaluate
    assert_equal "var", "false ? true : var".evaluate 
    assert_equal "var ? var0 : 1", "var ? var0 : 1".evaluate 
  end

  def tear_down
  end
end

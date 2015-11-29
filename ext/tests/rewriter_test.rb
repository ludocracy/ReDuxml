require_relative '../symja'
require 'minitest/autorun'

# tests term formatting - without regard to validity of evaluation
class RewriterTest < MiniTest::Test
  @e
  attr_reader :e
  def setup
    @e = Symja.new
  end

  def test_rh_negated_boolean
    assert_equal "true", e.evaluate("!var == !var")
    assert_equal "true", e.evaluate("var != !var")
    puts "test_rh_negated_boolean passed"
  end

  def test_lower_case_conversion
    assert_equal "true", e.evaluate("true")
    assert_equal "false", e.evaluate("false")
    puts "test_lower_case_conversion passed"
  end

  # def test_logic_filter  end

  def test_integer_preference
    assert_equal "var/2", e.evaluate("var/2")
    assert_equal "2/var", e.evaluate("2/var")
    assert_equal "2+var", e.evaluate("var+4-2")
    assert_equal "2*var", e.evaluate("var+var")
    assert_equal "var^2", e.evaluate("var*var")
    assert_equal "1", e.evaluate("var/var")
    assert_equal "-1+2*var", e.evaluate("var*2-1")
    assert_equal "-2+var", e.evaluate("var-2*1")
    assert_equal "2-var", e.evaluate("2-1*var")
    assert_equal "2-1/var", e.evaluate("2-1/var")
    assert_equal "2*var", e.evaluate("var*2/1")
    assert_equal "-1+var/2", e.evaluate("var/2-1")
    assert_equal "2*var", e.evaluate("2/1*var")
    assert_equal "2-var", e.evaluate("2/1-var")
    assert_equal "2*var", e.evaluate("var/2*4")
    assert_equal "2*var", e.evaluate("var*4/2")
    assert_equal "-2+2*var", e.evaluate("var-2+var")
    assert_equal "-var", e.evaluate("var-2*var")
    assert_equal "var", e.evaluate("var*2-var")
    assert_equal "3/2*var", e.evaluate("var/2+var")
    assert_equal "2+2*var", e.evaluate("var-2+4+var")
    assert_equal "-7*var", e.evaluate("var-2*4*var")
    assert_equal "3*var", e.evaluate("var/2*4+var")
    assert_equal "1+3*var", e.evaluate("1+var/2*4+var")
    puts "test_integer_preference passed"
  end

  def test_rational_preference
    assert_equal "1/2", e.evaluate("1/2")
    assert_equal "var/2", e.evaluate("var/2")
    assert_equal "1/var", e.evaluate("1/var")
    puts "test_rational_preference passed"
  end

  def test_ternary
    assert_equal "10", e.evaluate("1==2?3==4?5:6==7?8:9:10")
    assert_equal "var", e.evaluate("var ? true : false")
    assert_equal "var", e.evaluate("true ? var : false")
    assert_equal "var", e.evaluate("false ? true : var")
    assert_equal "var ? var0 : 1", e.evaluate("var ? var0 : 1")
    puts "test_ternary passed"
  end

  def tear_down

  end

end # end of RewriterTest

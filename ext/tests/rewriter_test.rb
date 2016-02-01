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

  def test_ternary
    assert_equal "2", e.evaluate("1==1?2:3==3?4:5")
    assert_equal "10", e.evaluate("1==2?3==4?5:6==7?8:9:10")
    puts "test_ternary passed"
  end

  def test_var_ternary
    assert_equal "var", e.evaluate("var ? true : false")
    assert_equal "var", e.evaluate("true ? var : false")
    assert_equal "var", e.evaluate("false ? true : var")
    assert_equal "If[var,var0,1]", e.evaluate("var ? var0 : 1")
    puts "test_var_ternary passed"
  end

  def test_substitution
    result = e.evaluate("param", {param: {string: 'should not'}})
    assert_equal "should not", result
  end

  def tear_down

  end

end # end of RewriterTest

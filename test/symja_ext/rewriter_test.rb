require File.expand_path(File.dirname(__FILE__) + '/../../../Dux/lib/dux/ruby_ext/regexp')
require File.expand_path(File.dirname(__FILE__) + '/../../lib/symja_ext/symja')
require 'minitest/autorun'

# test term formatting - without regard to validity of evaluation
class RewriterTest < MiniTest::Test
  @e
  attr_reader :e
  def setup
    @e = Symja.instance
  end

  def test_rh_negated_boolean
    assert_equal "true", e.evaluate("!var == !var")
    assert_equal "true", e.evaluate("var != !var")
  end

  def test_lower_case_conversion
    assert_equal "true", e.evaluate("true")
    assert_equal "false", e.evaluate("false")
  end

  # def test_logic_filter  end

  def test_ternary
    assert_equal "2", e.evaluate("1==1?2:3==3?4:5")
    assert_equal "10", e.evaluate("1==2?3==4?5:6==7?8:9:10")
  end

  def test_var_ternary
    assert_equal "var", e.evaluate("var ? true : false")
    assert_equal "var", e.evaluate("true ? var : false")
    assert_equal "var", e.evaluate("false ? true : var")
    assert_equal "If[var,var0,1]", e.evaluate("var ? var0 : 1")
  end

  def test_substitution
    result = e.evaluate("param", {param: {string: 'should not'}})
    assert_equal "should not", result
  end

  def tear_down

  end

end # end of RewriterTest

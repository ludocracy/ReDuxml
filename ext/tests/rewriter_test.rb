require_relative '../ext/ruby'
require 'minitest/autorun'

# tests term formatting - without regard to validity of evaluation
class RewriterTest < MiniTest::Test
  def setup
  end

  def test_logic_filter
    it "must raise" do
      assert_raises LogicException do
        ""
      end
      ->     { bar.do_it }.must_raise RuntimeError
      lambda { bar.do_it }.must_raise RuntimeError
      proc   { bar.do_it }.must_raise RuntimeError
    end
  end

  def test_boolean_lower_case
    assert_equal "true", "true".evaluate
    assert_equal "false", "false".evaluate
  end

  def test_var_negate_bug
    assert_equal "true", "!var == !var".evaluate
    assert_equal "true", "var != !var".evaluate
    assert_equal "!var", "!var".evaluate
    assert_equal "var", "!!var".evaluate
    assert_equal "!var", "!!!var".evaluate
    assert_equal "var1", "!var0 && var0 || var1".evaluate
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

require_relative '../logic'
require 'minitest/autorun'

class LogicTest < MiniTest::Test
  def setup
  end

  def test_regression
    assert_equal "true", "!var == !var".evaluate
    assert_equal "true", "var != !var".evaluate
  end

  def tear_down
  end
end

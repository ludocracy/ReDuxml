require_relative '../parameters'
require 'minitest/autorun'

class ParametersTest < MiniTest::Test
  def setup
  end

  def test_regression
    assert_equal "true", "!var == !var".evaluate
    assert_equal "true", "var != !var".evaluate
  end

  def tear_down
  end
end

require_relative '../design'
require 'minitest/autorun'

class DesignTest < MiniTest::Test
  def setup
  end

  def test_regression
    assert_equal "true", "!var == !var".evaluate
    assert_equal "true", "var != !var".evaluate
  end

  def tear_down
  end
end

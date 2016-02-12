require_relative '../string'
require 'minitest/autorun'

class StringParamedTest < MiniTest::Test
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  #
  def test_parameterized
    assert "asdf @(asd)".parameterized?
  end

  def test_not_parameterized
    assert !"asdf asd".parameterized?
  end
end
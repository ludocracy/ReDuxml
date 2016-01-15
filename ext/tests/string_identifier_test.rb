require_relative '../string'
require 'minitest/autorun'

class Object2XMLTest < MiniTest::Test
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  def test_whitespaces
    assert !"asdf asd".identifier?
  end

  def test_starting_numeral
    assert !"4asdfasd".identifier?
  end

  def test_illegal_char
    assert !"asdf-asd".identifier?
    assert !"asd!fasd".identifier?
    assert !"asdf()asd".identifier?
    assert !"asdf[]asd".identifier?
  end

  def test_valid_identifier
    assert "aDD323_sdf".identifier?
  end
end
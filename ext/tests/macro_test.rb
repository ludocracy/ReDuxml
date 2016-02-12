require_relative '../macro'
require 'minitest/autorun'

class MacroTest < MiniTest::Test
  def setup
    @m = Macro.new "2 + asdf"
    @n = Macro.new "2 + 4"
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  def test_demacro
    assert_equal "2 + asdf", @m.demacro
  end

  def test_parameterized
    assert @m.parameterized?
    assert !@n.parameterized?
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
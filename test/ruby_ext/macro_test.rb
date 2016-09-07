require File.expand_path(File.dirname(__FILE__) +  '/../../lib/ruby_ext/macro')
require File.expand_path(File.dirname(__FILE__) +  '/../../lib/ruby_ext/string')

require 'test/unit'

class MacroTest < Test::Unit::TestCase
  def setup
    @m = Macro.new "2 + asdf"
    @n = Macro.new "2 + 4"
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_is_macro
    assert_equal true, Macro.is_macro?('@(asdf)')
  end

  # Fake test
  def test_demacro
    assert_equal "2 + asdf", @m.demacro
  end

  def test_parameterized
    assert @m.parameterized?
    assert !@n.parameterized?
  end
end

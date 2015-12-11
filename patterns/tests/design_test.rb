require_relative '../design'
require 'minitest/autorun'

class DesignTest < MiniTest::Test
  def setup
  end

  def test_init_nil
    @d = Patterns::Design.new
    assert d.respond_to?(:logic)
  end

  def tear_down
  end
end

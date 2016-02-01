require_relative '../design'
require 'minitest/autorun'

class DesignTest < MiniTest::Test
  include Patterns

  attr_reader :test_str

  def setup
    @test_str = "<design><poop>fan</poop></design>"
  end

  def test_init_logic
    assert true
  end

  def tear_down
  end
end

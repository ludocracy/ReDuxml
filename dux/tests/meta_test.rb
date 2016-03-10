require File.expand_path(File.dirname(__FILE__) + '/../meta')
require 'minitest/autorun'

class DuxerTest < MiniTest::Test
  SAMPLE_DUX = File.expand_path(File.dirname(__FILE__) + '/../tests/xml/sample_dux.xml')
  # Called before every test method runs. Can be used
  # to set up fixture information.

  def setup
  end

  def test_init_enhanced_design
    m = Meta.new SAMPLE_DUX
    m2 = Meta.new m.design
    assert_equal 'design', m2.design.type

  end

  def teardown
  end
end
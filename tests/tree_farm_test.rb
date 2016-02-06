require_relative '../tree_farm'
require 'minitest/autorun'

class TreeFarmTest < MiniTest::Test
  SAMPLE_TEMPLATE = 'xml/sample_template.xml'
  RESULT_TEMPLATE = 'xml/result_template.xml'
  include Patterns
  # Called before every test method runs. Can be used
  # to set up fixture information.

  attr_reader :t, :r
  def setup
    g = TreeFarm.instance
    @t = g.load SAMPLE_TEMPLATE
    @r = g.grow t
  end

  def test_load_template
    assert t.is_a?(Template)
  end

  def test_if_resolution
    assert_equal nil, r.design.find_child(:instance)
  end

  def test_inline_resolution
    p_test = r.design.find_child(%w(array p_test))
    assert_equal '0 is a design param expression', p_test.content
  end

  def test_kansei_traverse
    assert_equal t.find_child(%w(design array p_test)).content, r.abstraction.find_child(%w(design array p_test)).content
    #assert_equal r.find_child(%w(design array p_test)).content, t.kansei_to(t.design.params.to_hash).find_child(%w(design array p_test)).content
  end

  def teardown
  end
end

require_relative '../tree_farm'
require 'minitest/autorun'

class TreeFarmTest < MiniTest::Test
  SAMPLE_TEMPLATE = 'xml/sample_template.xml'
  RESULT_TEMPLATE = 'xml/result_template.xml'
  include Patterns
  # Called before every test method runs. Can be used
  # to set up fixture information.

  attr_reader :b, :g
  def setup
  end

  def test_load_template
    g = TreeFarm.new
    b = g.plant SAMPLE_TEMPLATE
    assert b.is_a?(Template)
  end

  def test_if_resolution
    g = TreeFarm.new
    g.plant 'xml/conditionals.xml'
    t = g.grow.design
    assert_equal nil, t.find_child(:should_be_false)
    assert_equal 'should_be_true', t.find_child(:should_be_true).id
    assert_equal 'unconditional_comp', t.find_child(:unconditional_comp).id
  end

  def test_inline_resolution
    g = TreeFarm.new
    g.plant 'xml/inline_param.xml'
    d = g.grow.design
    p_test = d.find_child(%w(blah p_test))
    assert_equal '0 is a design param expression', p_test.content
  end

  def test_save_kansei
    g = TreeFarm.new
    g.plant 'xml/inline_param.xml'
    g.grow
    g.save RESULT_TEMPLATE
    x = File.read(RESULT_TEMPLATE)
    d = Template.new(x).design
    p_test = d.find_child(%w(blah p_test))
    assert_equal '0 is a design param expression', p_test.content
  end

  def test_kansei_traverse
    skip
    g = TreeFarm.new
    b = g.plant SAMPLE_TEMPLATE
    t = g.grow
    assert t === g.current_template
    assert b === g.base_template
  end

  def test_instantiate_ref
    skip
    g = TreeFarm.new
    g.plant 'xml/simple_inst.xml'
    t = g.grow
    assert_equal 'this is a design component', t.design.find_child(%w(blah some_component)).content
  end

  def test_instantiate_array
    skip
    g = TreeFarm.new
    g.plant 'xml/array_inst.xml'
    c = g.grow.design
    assert_equal '4 is an iterator expression', c.find_child(:iterator_test3).content
  end

  def test_param_overrides
    skip
    g = TreeFarm.new
    g.plant 'xml/param_override.xml'
    c = g.grow.design
    assert_equal 'this component thinks param0 = 0', c.find_child(:some_component).content
    assert_equal 'this component should also say param0 = 0', c.find_child(:param_overrides_inst)
  end

  def test_derived_params
    skip
    g = TreeFarm.new
    g.plant 'xml/derived_params.xml'
    c = g.grow.design
    assert_equal '30 is a derived resolved value', c.find_child(%w(blah resolvable)).content
    assert_equal '@(monkey) is a derived unresolved value', c.find_child(%w(blah unresolvable)).content
  end

  def test_link_design
    # INCOMPLETE REQUIREMENTS!!!
  end

  def teardown
    #File.delete RESULT_TEMPLATE if File.exists?(RESULT_TEMPLATE)
  end
end

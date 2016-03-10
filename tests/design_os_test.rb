require File.expand_path(File.dirname(__FILE__) + '/../design_os')
require 'minitest/autorun'

class DuxerTest < MiniTest::Test
  SAMPLE_DUX = File.expand_path(File.dirname(__FILE__) + '/../tests/xml/sample_dux.xml')
  # Called before every test method runs. Can be used
  # to set up fixture information.

  attr_reader :b, :g
  def setup
  end

  def test_load_dux
    g = Duxer.new
    b = g.load SAMPLE_DUX
    assert b.is_a?(Meta)
  end

  def test_instantiation_history
    g = Duxer.new
    b = g.load SAMPLE_DUX
    t = g.resolve.design
    g.save RESULT_DUX
    assert_equal 'history', t.parent.history.type
    # check for parameter-overrides as attr value changes
    # check for instantiations as inserts
    # check for prunings as removes
    # check total number of changes
    # check order? yes. to detect instability in private methods.
  end

  def test_if_resolution
    g = Duxer.new
    g.load File.expand_path(File.dirname(__FILE__) + '/xml/conditionals.xml')
    t = g.resolve.design
    assert_equal nil, t.find_child(:should_be_false)
    assert_equal 'should_be_true', t.find_child(:should_be_true).id
    assert_equal 'unconditional_comp0', t.find_child(:unconditional_comp).id
  end

  def test_inline_resolution
    g = Duxer.new
    g.load File.expand_path(File.dirname(__FILE__) + '/xml/inline_param.xml')
    d = g.resolve.design
    p_test = d.find_child(%w(blah p_test))
    assert_equal '0 is a design param expression', p_test.content
  end

  def test_save_dux
    skip
    g = Duxer.new
    g.load File.expand_path(File.dirname(__FILE__) + '/xml/inline_param.xml')
    g.resolve
    g.save RESULT_DUX
    x = File.read(RESULT_DUX)
    d = Meta.new(x).design
    p_test = d.find_child(%w(blah p_test))
    assert_equal '0 is a design param expression', p_test.content
  end

  def test_dux_traverse
    g = Duxer.new
    b = g.load SAMPLE_DUX
    t = g.resolve
    assert t === g.current_dux
    assert b === g.base_dux
  end

  def test_instance_name_collision
    g = Duxer.new
    g.load File.expand_path(File.dirname(__FILE__) + '/xml/component_collision.xml')
    t = g.resolve
    assert_equal 'this design component should collide', t.design.children[0].content
    assert_equal 'with this component!', t.design.children[1].content
  end

  def test_instantiate_ref
    g = Duxer.new
    g.load File.expand_path(File.dirname(__FILE__) + '/xml/simple_inst.xml')
    t = g.resolve
    assert_equal 'this is a design component', t.design.find_child(%w(blah some_component)).content
  end

  def test_instantiate_array
    g = Duxer.new
    g.load File.expand_path(File.dirname(__FILE__) + '/xml/array_inst.xml')
    c = g.resolve.design
    assert_equal '4 is an iterator expression', c.find_child('iterator_test.array_id3').content
  end

  def test_param_overrides
    g = Duxer.new
    g.load File.expand_path(File.dirname(__FILE__) + '/xml/param_override.xml')
    c = g.resolve.design
    assert_equal 'this component thinks param0 = 0', c.find_child(:overriding).content
    assert_equal 'this component should also say param0 = 0', c.find_child(:overridden).content
  end

  def test_nonidentical_insts
    g = Duxer.new
    g.load File.expand_path(File.dirname(__FILE__) + '/xml/fraternal_twins.xml')
    c = g.resolve.design
    assert_equal 'for this instance, param0 == 0', c.children.first.content
    assert_equal 'but for this instance, param0 == 10', c.children.last.content
  end

  def test_derived_params
    g = Duxer.new
    g.load File.expand_path(File.dirname(__FILE__) + '/xml/derived_params.xml')
    c = g.resolve.design
    assert_equal '30 is a derived resolved value', c.find_child(%w(blah resolvable)).content
    assert_equal '@(monkey) is a derived unresolved value', c.find_child(%w(blah unresolvable)).content
  end

  def test_link_design
    # INCOMPLETE REQUIREMENTS!!!
  end

  def teardown
  end
end
require File.expand_path(File.dirname(__FILE__) + '/../lib/re_duxml')
require 'test/unit'

class DuxerTest < Test::Unit::TestCase
  SAMPLE_FILE = File.expand_path(File.dirname(__FILE__) + '/../xml/sample.xml')
  RESULT_FILE = File.expand_path(File.dirname(__FILE__) + '/../xml/result.xml')
  LOGIC_FILE = File.expand_path(File.dirname(__FILE__) + '/../xml/logic.xml')

  # Called before every test method runs. Can be used
  # to set up fixture information.

  include ReDuxml

  def setup
    load SAMPLE_FILE
  end

  def test_instantiation_history
    resolve SAMPLE_FILE
    assert_equal 'history', meta.history.type
    # check for parameter-overrides as attr value changes
    # check for instantiations as inserts
    # check for prunings as removes
    # check total number of changes
    # check order? yes. to detect instability in private methods.
  end

  def test_if_resolution
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/conditionals.xml')
    assert_equal nil, doc(:should_be_false)
    assert_equal 'should_be_true', doc(:should_be_true).id
    assert_equal 'unconditional_comp0', doc(:unconditional_comp).id
  end

  def test_inline_resolution
    omit
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/inline_param.xml')
    p_test = d.find_child(%w(blah p_test))
    assert_equal '0 is a design param expression', p_test.content
  end

  def test_param_overrides
    omit
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/param_override.xml')
    assert_equal 'this component thinks param0 = 0', c.find_child(:overriding).content
    assert_equal 'this component should also say param0 = 0', c.find_child(:overridden).content
  end

  def test_nonidentical_insts
    omit
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/fraternal_twins.xml')
    assert_equal 'for this instance, param0 == 0', c.children.first.content
    assert_equal 'but for this instance, param0 == 10', c.children.last.content
  end

  def test_derived_params
    omit
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/derived_params.xml')
    assert_equal '30 is a derived resolved value', c.find_child(%w(blah resolvable)).content
    assert_equal '@(monkey) is a derived unresolved value', c.find_child(%w(blah unresolvable)).content
  end

  def test_link_design
    # INCOMPLETE REQUIREMENTS!!!
  end

  def teardown
  end
end
require_relative '../template'
require 'minitest/autorun'
require 'nokogiri'
SAMPLE_TEMPLATE = 'xml/sample_template.xml'

class HistoryTest < MiniTest::Test
  include Patterns
  def setup
    @t = Template.new Nokogiri::XML File.read SAMPLE_TEMPLATE
  end

  attr_accessor :t

  def test_add_child
    t.design << Component.new(%(<test id="test_0"/>))
    c = t.history.first
    assert_equal 'insert', c.type
    assert_equal %(Component 'test_0' of type 'test' was added to component 'design_id' of type 'design'.), c.description
  end

  def test_remove_child
    t.design.remove 'test_instance_0_id'
    c = t.history.first
    assert_equal 'remove', c.type
    assert_equal %(Component 'test_instance_0_id' of type 'instance' was removed from component 'design_id' of type 'design'.), c.description
  end

  def test_new_attr
    t.design.find_child('targetiddxcz')[:new_attribute] = 'new value'
    c = t.history.first
    assert_equal 'new_attribute', c.type
    assert_equal %(Component 'targetiddxcz' of type 'thing' given new attribute 'new_attribute' with value 'new value'.), c.description
  end

  def test_new_content
    t.design.find_child('thing1').content = 'new content'
    c = t.history.first
    assert_equal 'new_content', c.type
    assert_equal %(Component 'thing1' of type 'thing' given new content 'new content'.), c.description
  end

  def test_change_attr
    t.design.find_child('test_instance_0_id')[:visible] = 'new value'
    c = t.history.first
    assert_equal 'change_attribute', c.type
    assert_equal %(Component 'test_instance_0_id' of type 'instance' changed attribute 'visible' value from 'debug !customer' to 'new value'.), c.description
  end

  def test_change_content
    t.design.find_child('targetiddxcz').content = 'new content'
    c = t.history.first
    assert_equal 'change_content', c.type
    assert_equal %(Component 'targetiddxcz' of type 'thing' changed content from 'something something' to 'new content'.), c.description
  end

  def test_change_param

  end

  def test_change_order
    # check to make sure changes are stacked latest first, first last
  end

  def tear_down
  end
end

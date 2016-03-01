require_relative '../design'
require_relative '../../patterns/template'
require 'minitest/autorun'
SAMPLE_TEMPLATE = 'C:\Users\b33791\RubymineProjects\DesignOS\patterns\component\tests\xml\sample_template.xml'

class DesignTest < MiniTest::Test
  include Patterns

  attr_reader :d

  def setup
    @d = Design.new %(<design><instance id="outer"><instance id="inner"/></instance></design>)
  end

  def test_find_kansei
    c = Instance.new(%(<instance id="inner"/>))
    x = d.find_kansei c
    assert_equal c.name, x.name
  end

  def test_load_from_template
    t = Patterns::Template.new SAMPLE_TEMPLATE
    assert_equal 'design', t.design.type
  end

  def test_link_instantiate
    #l = Link.new(%())
  end

  def test_instance_instantiate
    i = Instance.new(%(<instance id="outer"><child/></instance>))
    c = i.instantiate nil
    assert_equal 'child', c.first.name
  end

  def test_instance_instantiate_params
    i = Instance.new(%(<instance id="outer"><parameters><parameter name="param" value="10"/></parameters><child></child></instance>))
    c = i.instantiate nil
    assert c.size == 1
    assert_equal 'child', c.first.name
  end

  def test_array_instantiate
    a = Patterns::Array.new(%(<array size="10"><car/></array>))
    c = a.instantiate
    assert_equal 10, c.size
    assert_equal '9', c.last.params[:iterator]
  end

  def tear_down
  end
end

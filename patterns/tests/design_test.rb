require_relative '../design'
require 'minitest/autorun'

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
    #a = Patterns::Array.new.instantiate
  end

  def tear_down
  end
end

require File.expand_path(File.dirname(__FILE__) + '/../../lib/dux_ext/design')
require 'minitest/autorun'

class DesignTest < MiniTest::Test
  include Dux

  def setup
  end


  def test_link_instantiate
    #l = Link.new(%())
  end

  def test_instance_instantiate
    i = Instance.new(%(<instance id="outer"><child id="child0"/></instance>))
    c = i.instantiate nil
    assert_equal 'child0', c.first.name
  end

  def test_instance_instantiate_params
    i = Instance.new(%(<instance id="outer"><parameters><parameter name="param" value="10"/></parameters><child id="child0"></child></instance>))
    c = i.instantiate nil
    assert c.size == 1
    assert_equal 'child0', c.first.name
  end

  def test_array_instantiate
    a = Dux::Array.new(%(<array size="10"><car/></array>))
    c = a.instantiate
    assert_equal 10, c.size
    assert_equal '9', c.last.params[:iterator]
  end

  def tear_down
  end
end

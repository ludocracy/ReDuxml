require File.expand_path(File.dirname(__FILE__) + '/../../dux_object')
require 'minitest/autorun'

class ParameterizationTest < MiniTest::Test
  SAMPLE_TEMPLATE_FILE = File.expand_path(File.dirname(__FILE__) + '/../../tests/xml/sample_dux.xml')

  attr_reader :e
  def setup
    @e = DuxObject.new(%(<birdhouse id="birdhouse0" color="red" size="large"/>))
  end

  def test_get_parameterized_nodes
    a = DuxObject.new(%(<design><birdhouse id="birdhouse0" attr="@(param)">@(pine)<color/><material><wood>pine</wood></material></birdhouse></design>))
    t = a.detached_subtree_copy
    s = []
    t.find_child(:birdhouse).parameterized_xml_nodes.each do |node| s << node.to_s end
    assert_equal %w(@(param) @(pine)), s
  end

  def test_if
    f = DuxObject.new(%(<birdhouse if="false">@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    t = DuxObject.new(%(<birdhouse if="true">@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal false, f.if?
    assert_equal true, t.if?
  end

  def test_no_if
    t = DuxObject.new(%(<birdhouse>@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal true, t.if?
  end
end
require File.expand_path(File.dirname(__FILE__) + '/../../../lib/dux_ext/object')
require 'minitest/autorun'

class ParameterizationTest < MiniTest::Test
  SAMPLE_TEMPLATE_FILE = File.expand_path(File.dirname(__FILE__) + '/../../../xml/sample_dux.xml')

  attr_reader :e
  def setup
    @e = Dux::Object.new(%(<birdhouse id="birdhouse0" color="red" size="large"/>))
  end

  def test_get_parameterized_nodes
    a = Dux::Object.new(%(<design><birdhouse id="birdhouse0" attr="@(param)">@(pine)<color/><material><wood>pine</wood></material></birdhouse></design>))
    t = a.detached_subtree_copy
    s = []
    t.find_child(:birdhouse).parameterized_xml_nodes.each do |node| s << node.to_s end
    assert_equal %w(@(param) @(pine)), s
  end

  def test_if
    f = Dux::Object.new(%(<birdhouse if="false">@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    t = Dux::Object.new(%(<birdhouse if="true">@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal false, f.if?
    assert_equal true, t.if?
  end

  def test_no_if
    t = Dux::Object.new(%(<birdhouse>@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal true, t.if?
  end
end
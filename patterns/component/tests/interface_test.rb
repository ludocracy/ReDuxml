require_relative '../component'
require 'minitest/autorun'
require 'nokogiri'
# tests term formatting - without regard to validity of evaluation
class InterfaceTest < MiniTest::Test
  SAMPLE_TEMPLATE_FILE = 'xml/sample_template.xml'
  include Components
  @e
  attr_reader :e
  def setup
    @e = Component.new(%(<birdhouse color="red" size="large"/>))
  end

  def test_to_s
    answer = %(<birdhouse color="red" size="large"/>)
    assert_equal answer, e.to_s
  end

  def test_promote_attr
    answer = %(<birdhouse size="large"><color>red</color></birdhouse>)
    e.promote(:color)
    assert_equal answer, e.to_s
  end

  def test_add_child
    answer = %(<birdhouse color="red" size="large"><material>pine</material></birdhouse>)
    e << Component.new(%(<material>pine</material>))
    assert_equal answer, e.to_s
  end

  def test_get_attr
    assert_equal 'large', e[:size]
  end

  def test_find_child
    t = Component.new(%(<birdhouse><color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal 'pine', t.find_child(%w(material wood)).content
  end

  def test_stub
    t = Component.new(%(<birdhouse><color/><material><wood>pine</wood></material></birdhouse>))
    s = t.stub
    assert_equal %(<birdhouse/>), s.xml.to_s
    assert_equal 0, s.children.size
  end

  def test_remove
    t = Component.new(%(<birdhouse><color/><material><wood>pine</wood></material></birdhouse>))
    c = t.find_child('material')
    t.remove c
    assert_equal %(<birdhouse><color/></birdhouse>), t.xml.to_s
  end

  def test_get_parameterized_nodes
    t = Component.new(%(<design><birdhouse attr="@(param)">@(pine)<color/><material><wood>pine</wood></material></birdhouse></design>))
    s = []
    t.find_child(:birdhouse).parameterized_nodes.each do |node| s << node.to_s end
    assert_equal %w(@(param) @(pine)), s
  end

  def test_if
    f = Component.new(%(<birdhouse if="false">@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    t = Component.new(%(<birdhouse if="true">@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal false, f.if?
    assert_equal true, t.if?
  end

  def test_no_if
    t = Component.new(%(<birdhouse>@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal true, t.if?
  end

  def test_type_and_id
    t = Component.new(%(<birdhouse id="jerrys">@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal 'birdhouse', t.type
    assert_equal 'jerrys', t.id
  end

  def test_descended_from
    t = Component.new(%(<birdhouse>@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    r = t.find_child(%w(material wood))
    assert_equal true, r.descended_from?(:birdhouse)
    assert_equal false, r.descended_from?(:color)
  end
end

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
    stub = t.stub
    x = stub.xml.to_s
    assert_equal %(<birdhouse/>), x
  end

  def test_remove
    t = Component.new(%(<birdhouse><color/><material><wood>pine</wood></material></birdhouse>))
    c = t.find_child('material')
    t.remove c
    assert_equal %(<birdhouse><color/></birdhouse>), t.xml.to_s
  end
end

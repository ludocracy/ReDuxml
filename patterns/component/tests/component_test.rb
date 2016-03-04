require_relative '../component'
require 'minitest/autorun'

# tests term formatting - without regard to validity of evaluation
class ComponentTest < MiniTest::Test
  include Components
  @e
  attr_reader :e
  def setup
  end

  def test_init_nil
   assert_equal 'component', Component.new(nil).type
  end

  def test_init_str
    test_xml = Nokogiri::XML("<poop/>").root
    @e = Component.new(test_xml.to_s)
    assert_equal test_xml.to_s, e.xml.to_s
  end

  def test_init_simple
    test_xml = Nokogiri::XML("<poop/>").root
    @e = Component.new(test_xml)
    assert_equal test_xml.to_s, e.xml.to_s
  end

  def test_init_attr
    test_xml = Nokogiri::XML("<poop color=\"green\"/>").root
    @e = Component.new(test_xml.to_s)
    assert_equal test_xml.to_s, e.xml.to_s
    assert_equal "green", e[:color].to_s
  end

  def test_init_content
    test_xml = Nokogiri::XML("<poop>pooper</poop>").root
    @e = Component.new(test_xml)
    assert_equal 'pooper', e.content
  end

  def test_init_hierarchy
    @e = Component.new("<poop><danglers>dangling</danglers><chunks>chunky</chunks></poop>")
    child0 = e.find_child(:danglers)
    child1 = e.find_child(:chunks)
    assert_equal "<danglers>dangling</danglers>", child0.xml.to_s
    assert_equal "<chunks>chunky</chunks>", child1.xml.to_s
  end

  def tear_down

  end

end # end of RewriterTest

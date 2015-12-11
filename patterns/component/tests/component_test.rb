require_relative '../component'
require 'minitest/autorun'

# tests term formatting - without regard to validity of evaluation
class ComponentTest < MiniTest::Test
  @e
  attr_reader :e
  def setup
  end

  def test_init_nil
   assert_raises (ArgumentError) do Patterns::Component.new(nil) end
  end

  def test_init_simple
    test_xml = Nokogiri::XML("<poop/>").root
    @e = Patterns::Component.new(test_xml.to_s)
    assert_equal test_xml.to_s, e.xml.to_s
  end

  def test_init_attr
    test_xml = Nokogiri::XML("<poop color=\"green\"/>").root
    @e = Patterns::Component.new(test_xml.to_s)
    assert_equal test_xml.to_s, e.xml.to_s
    assert_equal "green", e[:color].to_s
  end

  def test_init_hierarchy
    @e = Patterns::Component.new("<poop><danglers/><chunks/></poop>")
    child0 = e.find_child(:danglers)
    child1 = e.find_child(:chunks)
    assert_equal "<danglers/>", child0.xml.to_s
    assert_equal "<chunks/>", child1.xml.to_s
  end

  def test_add_child
    @e = Patterns::Component.new("<poop><danglers/></poop>")
    test_xml = Nokogiri::XML("<jangles/>").root
    j = Patterns::Component.new(test_xml.to_s)
    @e.find_child(:danglers) << j
    child0 = e.find_child(:jangles)
    assert_equal test_xml.to_s, child0.xml.to_s
  end

  def tear_down

  end

end # end of RewriterTest

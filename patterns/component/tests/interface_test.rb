require_relative '../component'
require 'minitest/autorun'
require 'nokogiri'
# tests term formatting - without regard to validity of evaluation
class InterfaceTest < MiniTest::Test
  include Patterns
  @e
  attr_reader :e
  def setup
    @e = Patterns::Component.new("<poop color=\"brown\" smell=\"vile\"/>")
  end

  def test_xml
    answer = Nokogiri::XML("<poop color=\"brown\" smell=\"vile\"/>").root.to_s
    assert_equal answer, e.xml.to_s
  end

  def test_promote
    answer = Nokogiri::XML("<smell>vile</smell>").root.to_s
    e.promote(:smell)
    reply = e.find_child(:smell)
    assert_equal answer, reply.xml.to_s
  end

  def test_promote_attr
    answer = Nokogiri::XML("<poop smell=\"vile\"><color shade=\"brown\"/></poop>").root.to_s
    assert_equal answer, e.promote(:color, attr: "shade").xml.to_s
  end

  def test_promote_element
    answer = Nokogiri::XML("<poop color=\"brown\"><smell>vile</smell></poop>").root.to_s
    assert_equal answer, e.promote(:smell).xml.to_s
  end

end # end of RewriterTest

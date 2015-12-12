require_relative '../component'
require 'minitest/autorun'
require 'nokogiri'
# tests term formatting - without regard to validity of evaluation
class InterfaceTest < MiniTest::Test
  include Components
  @e
  attr_reader :e
  def setup
    @e = Component.new("<poop color=\"brown\" smell=\"vile\"><water color=\"clear\"/></poop>")
  end

  def test_xml
    answer = Nokogiri::XML("<poop color=\"brown\" smell=\"vile\"/>").root.to_s
    assert_equal answer, e.stub.to_s
  end

  def test_doc
    answer = Nokogiri::XML("<poop color=\"brown\" smell=\"vile\"><water color=\"clear\"/></poop>").root.to_s
    assert_equal answer, e.doc.root.to_s
  end

  def test_promote
    answer = Nokogiri::XML("<smell>vile</smell>").root.to_s
    e.promote(:smell)
    reply = e.find_child(:smell).stub.to_s
    assert_equal answer, reply
  end

  def test_promote_attr
    answer = Nokogiri::XML("<poop smell=\"vile\"><water color=\"clear\"/><color shade=\"brown\"/></poop>").root
    e.promote(:color, attr: "shade")
    assert_equal answer.name, e.doc.root.name
    assert_equal answer.content, e.doc.root.content
  end

  def test_promote_element
    answer = Nokogiri::XML("<poop color=\"brown\"><water color=\"clear\"/><smell>vile</smell></poop>").root.to_s
    e.promote(:smell)
    assert_equal answer, e.doc.root.to_s
  end

end # end of RewriterTest

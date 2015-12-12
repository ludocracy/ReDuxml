require_relative '../design'
require 'minitest/autorun'

class DesignTest < MiniTest::Test
  include Designs

  attr_reader :test_str

  def setup
    @test_str = "<design><poop>fan</poop></design>"
  end

  def test_init_logic
    design = Design.new("<design/>")
    assert design.respond_to?(:logic)
  end

  def test_str_init
    doc = Nokogiri::XML(test_str)
    design = Design.new(test_str)
    assert_equal doc.root.name, design.find_child(:poop).doc.root.name
    assert_equal doc.root.content, design.find_child(:poop).doc.root.content
  end

  def test_xml_init
    doc = Nokogiri::XML(test_str)
    design = Design.new(doc.root)
    assert_equal doc.root.name, design.find_child(:poop).doc.root.name
    assert_equal doc.root.content, design.find_child(:poop).doc.root.content
  end

  def tear_down
  end
end

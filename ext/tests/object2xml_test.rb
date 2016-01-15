require_relative '../object'
require 'minitest/autorun'

class Object2XMLTest < MiniTest::Test
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  # Fake test
  def test_fail
    assert "".xml.nil?
    assert " ".xml.nil?
    assert nil.xml.nil?
  end

  def test_true
    assert "<poop/>".xml
    assert "<poop></poop>"
    assert "<pooper>poop</pooper>"
  end

  def test_get_xml
    assert "<poop>".xml.is_a?(Nokogiri::XML::Element)
  end
end
require_relative '../xml'
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
  def test_element_string
    standard = %(<poop/>).xml.to_s
    assert_equal standard, element('poop').to_s
  end

  def test_element_array
    standard = %(<poop a="A" b="B">pooper</poop>).xml.to_s
    assert_equal standard, element('poop', {a: 'A', b: 'B'}, 'pooper').to_s
  end

  def test_element_array_no_content
    standard = %(<poop a="A" b="B">pooper</poop>).xml.to_s
    assert_equal standard, element('poop', {a: 'A', b: 'B'}, 'pooper').to_s
  end

  def test_element_array_no_attrs
    standard = %(<poop a="A" b="B">pooper</poop>).xml.to_s
    assert_equal standard, element('poop', {a: 'A', b: 'B'}, 'pooper').to_s
  end

  def test_element_array_name_only
    standard = %(<poop a="A" b="B">pooper</poop>).xml.to_s
    assert_equal standard, element('poop', {a: 'A', b: 'B'}, 'pooper').to_s
  end
end
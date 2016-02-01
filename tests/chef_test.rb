require_relative '../chef'
require 'minitest/autorun'

class ChefTest < MiniTest::Test
  # Called before every test method runs. Can be used
  # to set up fixture information.
  include Chef

  def setup

  end

  FILE = 'xml/sample_template.xml'
  NCFILE = 'xml/test.xml'

  def test_open
    assert open(FILE).is_a?(Patterns::Template)
  end

  def test_load_non_compliant_design
    t = open(NCFILE)
    assert_equal 'crr:UniversalDevice', t.design.name
  end

  def test_save
    t = open(NCFILE)
    assert save ("test.xml")
  end

  def test_interface_access
    #content
  end

  def test_navigation
    #child
    #parent
    #sibling
    #root
  end

  def teardown

  end
end

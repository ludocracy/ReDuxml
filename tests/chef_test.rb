require_relative '../chef'
require 'minitest/autorun'

class ChefTest < MiniTest::Test
  # Called before every test method runs. Can be used
  # to set up fixture information.

  def setup
  end

  FILE = 'xml/sample_template.xml'

  def test_load
    assert Chef.read(FILE)
  end

  def test_save
    assert Chef.save ("test.xml")
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

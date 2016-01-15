require_relative '../template'
require 'minitest/autorun'

# tests term formatting - without regard to validity of evaluation
class TemplateTest < MiniTest::Test
  include Templates
  def setup
  end

  def test_load_sample_template
    assert Template.new(Nokogiri::XML(File.read('xml/sample_template.xml')))
  end

  def tear_down
  end
end

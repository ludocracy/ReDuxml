require_relative '../template'
require 'minitest/autorun'

# tests term formatting - without regard to validity of evaluation
class TemplateTest < MiniTest::Test
  include Patterns
  attr_reader :template
  def setup
    @template = Template.new(File.read('xml/sample_template.xml'))
  end

  def test_sample_template_owner
    assert_equal 'b33791', template.owners[0].id
  end

  def test_sample_template_history
    a = template.history.children.first.name
    assert_equal 'insert', a
  end

  def test_sample_template_design
    assert_equal 'test_instance_0_id', template.design.find_child(:instance).id
  end

  def tear_down
  end
end

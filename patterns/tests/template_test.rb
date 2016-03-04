require_relative '../template'
require 'minitest/autorun'
SAMPLE_TEMPLATE = 'C:\Users\b33791\RubymineProjects\DesignOS\patterns\tests\xml\sample_template.xml'

# tests term formatting - without regard to validity of evaluation
class TemplateTest < MiniTest::Test
  include Patterns
  attr_reader :template
  def setup
    @template = Template.new SAMPLE_TEMPLATE
  end

  def test_sample_template_owner
    assert_equal 'b33791', template.owners[0].id
  end

  def test_sample_template_history
    a = template.history.children.first.type
    assert_equal 'insert', a
  end

  def test_sample_template_grammar
    a = template.grammar.children.first.type
    assert_equal 'rule', a
  end

  def test_sample_template_design
    assert_equal 'test_instance_0_id', template.design.find_child(:instance).id
  end

  def tear_down
  end
end

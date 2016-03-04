require_relative '../grammar'
require_relative '../../tree_farm'
require 'minitest/autorun'
SAMPLE_TEMPLATE = 'C:\Users\b33791\RubymineProjects\DesignOS\patterns\tests\xml\sample_template.xml'

class GrammarTest < MiniTest::Test
  include Patterns

  def setup
    @schema_rule = Rule.new nil, {subject: :thing, statement: %(%w(thing).include?(subject.object.type))}
    @f = TreeFarm.new
  end

  attr_accessor :schema_rule, :f

  def test_detect_error
    t = f.plant SAMPLE_TEMPLATE
    assert_equal 'rule', t.grammar.first_child.type
    assert_equal 'validate_error', t.history.first_child.type
    assert_equal 'targetiddxcz', t.history.first_child[:object]
  end

  def test_break_new_rule
    t = f.plant SAMPLE_TEMPLATE
    t.grammar << schema_rule
    t.design.find_child(:targetiddxcz) << Component.new(element 'everything')
    assert_equal 'qualify_error', t.history.first.type
    assert_equal 'targetiddxcz', t.history.first.non_compliant_object.id
  end

  def tear_down
  end
end

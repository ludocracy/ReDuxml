require_relative '../../../lib/re_duxml/evaluate/parser'
require 'test/unit'

class LexerTest < Test::Unit::TestCase
  include ReDuxml
  include Lexer

  def setup
    @logic = Parser.new(File.expand_path(File.dirname(__FILE__) + '/../../../xml/logic.xml')).logic
  end

  attr_reader :logic

  def test_tagging
    ts = lex('9 < 7').collect do |t| t.type end
    assert_equal [:num, :operator, :num], ts
  end

  def test_number_tagging
    ts = lex('90 < 70').collect do |t| t.type end
    assert_equal [:num, :operator, :num], ts
  end

  def test_prefix_unary
    vs = lex('!(var < 7)').collect do |t| t.value end
    assert_equal :prefix, vs.first.position
  end

  def test_num
    num = lex('9 < var').first.value
    assert_equal 9, num
  end

  def test_var
    var = lex('9 < var').last.value.class.to_s
    assert_equal 'Symbolic::Variable', var
    ts = lex('9 < var').collect do |t| t.type end
    assert_equal [:num, :operator, :param], ts
  end

  def test_string
  # TODO test re-substitution of strings here!
    ts = lex('"s s " != var').collect do |t| t.type end
    vs = lex('"s s " != var').collect do |t| t.value.to_s end
    assert_equal [:string, :operator, :param], ts
    assert_equal ['"s s "', '!=', 'var'], vs
  end

  def test_bool
    bool = lex('var ? true : 0')[2].value
    assert_equal true, bool
    ts = lex('var ? true : 0').collect do |t| t.type end
    assert_equal [:param, :operator, :bool, :grouping, :num], ts
  end

  def test_var_identity
    tokens = lex 'var - var'
    a, b, c =  *tokens.collect do |c| c.type end
    assert_equal a.class, c.class
    assert_equal a.object_id, c.object_id
  end

  def test_log

  end
end
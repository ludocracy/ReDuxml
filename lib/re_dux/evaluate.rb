require_relative 'evaluate/parser'
require_relative 'evaluate/lexer'
require_relative 'evaluate/operator'


module Evaluate
  include Parser
  include Lexer

  @logic

  attr_reader :logic

  def evaluate(_expr, param_hash)
    expr = _expr.dup
    # TODO pass in somehow? or move to module Operator ?
    load File.expand_path(File.dirname(__FILE__) + '/../../xml/logic.xml')
    @logic = {}
    doc.operators.each do |op| logic[op.symbol] = op end
    # TODO do substitution
    result = reduce parse expr
    result.parameterized? ? result.to_s : result
  end

  private

  def reduce(ast)
    ast.each do |node| node.reduce unless node.parameterized? end
  end
end # module ReDux
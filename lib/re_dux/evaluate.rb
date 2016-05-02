require_relative 'evaluate/parser'
require_relative 'evaluate/lexer'
require_relative 'evaluate/operable'


module Evaluate
  include Lexer

  @logic

  @param_hash

  attr_reader :logic, :param_hash

  def evaluate(_expr, _param_hash)
    @param_hash = _param_hash
    expr = resolve_params _expr
    # TODO do substitution
    result = reduce parse expr
    result.parameterized? ? result.to_s : result
  end

  private

  def resolve_params(_expr)
    expr = _expr.dup
    param_hash.each do |param, val| expr.gsub!(param, val) end
    expr
  end

  def reduce(ast)
    ast.each do |node| node.reduce unless node.parameterized? end
  end
end # module ReDux
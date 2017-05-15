# Copyright (c) 2016 Freescale Semiconductor Inc.
require_relative 'evaluate/parser'
require_relative '../../lib/ruby_ext/macro'

module ReDuxml
  class Evaluator
    LOGIC_FILE = File.expand_path(File.dirname(__FILE__) + '/../../xml/logic.xml')
    include Math
    include ReDuxml
    include Symbolic

    @param_hash
    @parser

    attr_reader :param_hash, :parser

    def initialize(logic=nil)
      @parser = Parser.new(logic || LOGIC_FILE)
      @param_hash = {}
    end

    def to_s
      "#<Evaluator: param_hash: '#{param_hash.to_s}' parser_logic: '#{parser}'>"
    end

    def evaluate(_expr, _param_hash={})
      @param_hash = _param_hash
      expr = resolve_params _expr
      return expr if expr.parameterized?
      return expr if Regexp.identifier.match(expr).to_s == expr
      return expr.to_i if expr.to_i.to_s == expr
      result = reduce parser.parse expr
      case
        when result.respond_to?(:imaginary), result.class == TrueClass, result.class == FalseClass then result
        when result.respond_to?(:name) then result.name
        when result.respond_to?(:to_sexp) then result.print(parser.logic)
        else result.to_s
      end
    end

    private

    def resolve_params(_expr)
      expr = _expr.dup
      param_hash.each do |param, val| expr.gsub!(param, val) end
      expr
    end

    include Symbolic

    def reduce(_ast)
      ast = _ast.type.respond_to?(:symbol) ? _ast : new_ast(parser.logic[_ast.type.to_s], _ast.children.dup)
      if ast.children.any?
        operator = ast.type
        args = ast.children.collect do |c|
          new_child = c.children.any? ? reduce(c) : c.type
          if new_child.is_a?(Node) && new_child.type.is_a?(Symbol)
            new_ast(parser.logic[new_child.type.to_s], *new_child.children.dup)
          else
            new_child
          end
        end.flatten
        begin
        result = case operator.position
                   when :prefix
                     method(operator.ruby).call(*args)
                   else
                     args.first.send(operator.ruby, *args[1..-1])
                 end
        result.nil? ? ast : result
        rescue
          ast
        end
      else
        ast
      end
    end # def reduce(ast)
  end # class Evaluator
end # module ReDux
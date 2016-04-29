require 'ast'
require_relative 'operator'
require_relative 'lexer'

module Parser
  include AST
  include Operator
  include Lexer

  private
  def parse(expr)
    @input = lex(expr)
    @output = []
    @op_stack = []

    return nil if input.empty?

    while (token = input.shift)
      case token.type
        when :num, :bool, :string, :param
          output.push AST::Node(token.type)
        when :operator
          op_prop = get_op(token)
          if token.right_associative?
            while op_stack.last && op_stack.last < AST::Operation && op_prop.precedence < op_stack.last.precedence
              consume
            end
          else
            while op_stack.last && op_stack.last < AST::Operation && op_prop.precedence <= op_stack.last.precedence
              consume
            end
          end
          op_stack.push op_prop

        when :grouping
          case token.value
            when :open
              if input.first && input.first.value == :close
                input.shift
                consume(0)
              else
                op_stack.push AST::Grouping
              end

            when :close
              while op_stack.any? && op_stack.last != AST::Grouping
                consume
              end

              lparen = op_stack.pop
              fail ParseError, "Unbalanced parenthesis" unless lparen == AST::Grouping

              if op_stack.last && op_stack.last < AST::Function
                consume(arities.pop.succ)
              end

            else
              fail ParseError, "Unknown grouping token #{ token.value }"
          end

        else
          fail ParseError, "Not implemented for tokens of category #{ token.category }"
      end
    end

    while op_stack.any?
      consume
    end

    unless output.count == 1
      fail ParseError, "Invalid statement"
    end

    output.first
  end

  def get_op(token)
    logic[token.value]
  end

  def consume(count=2)
    operator = op_stack.pop
    output.push AST::Node.new(operator.type, *get_args(operator.arity || count))
  end

  def get_args(count)
    Array.new(count) { output.pop }.reverse
  end
end

require 'duxml'
require_relative 'operator'
require_relative 'lexer'

module ReDuxml
  class Parser
    # hash of unique strings found in the parsed expression for substitution before (@see Lexer#lex) and
    # after parsing to allow parser to handle strings that may contain white spaces, operators, etc.
    @string_hash

    # array of Struct::Tokens from lexer
    @input

    # array of AST nodes produced by parser; can be popped to subordinate to higher precedence operation nodes
    @output

    # array of operator definitions (not classes!) in XML form, extended by module Operator
    @op_stack

    # hash of operator symbol strings to Operator object that contains properties and methods to access them
    @logic

    # stack to track argument count for operators requiring more than 2
    @arities

    attr_reader :string_hash, :logic
    attr_accessor :input, :output, :op_stack, :arities

    include Duxml
    include Lexer

    def to_s
      doc.logic.name
    end

    def initialize(_logic)
      if _logic
        load _logic
        @logic = {}
        doc.logic.Operator.each do |op|
          op.parent = @logic
          @logic[op.symbol] = op
        end
      end
      raise Exception if logic.nil?
    end

    # TODO attribute code to Dentaku
    def parse(expr)
      @input = lex(expr)
      @output = []
      @op_stack = []
      @arities = []

      return nil if input.empty?

      while(token = input.shift)
        case token.type
          when :num, :bool, :string, :param
            output.push AST::Node.new(token.value)
          when :operator
            op_prop = token.value
            arities << op_prop.arity-1 if op_prop.symbol == '?'
            if op_prop.right_associative?
              while op_stack.last && op_prop.precedence < op_stack.last.precedence
                if !op_stack.last.grouping?
                  consume
                else
                  break
                end
              end
            else
              while op_stack.last && op_prop.precedence <= op_stack.last.precedence && !op_stack.last.grouping?
                consume
              end
            end
            op_stack << op_prop
          when :function
            arities << 0
            op_stack << token.value
          when :grouping
            op_prop = token.value
            case op_prop.to_s
              when '('
                if input.any? && input.first.type == :grouping && input.first.value.to_s == '('
                  input.shift
                  consume(0)
                else
                  op_stack << op_prop
                end
              when ')'
                while op_stack.any? && op_stack.last.symbol != op_prop.pair.to_s
                  consume(arities.pop || op_stack.last.arity)
                end
                lparen = op_stack.pop
                fail ParseError, "Unbalanced parenthesis" unless lparen && lparen.grouping?

                if op_stack.last && op_stack.last.position == 'prefix'
                  consume(arities.pop)
                end
              when ','
                arities[-1] += 1
                while op_stack.any? && op_stack.last.symbol != '('
                  consume
                end
              when ':'
                while op_stack.any? && op_stack.last.symbol != '?'
                  consume(arities.pop)
                end
                arities[-1] += 1
                op_stack << op_prop
              else
                fail ParseError, "Unknown grouping token #{ token.value }"
            end # case token.value ... when :grouping
          else
            fail ParseError, "Not implemented for tokens of type #{ token.type }"
        end # case token.type
      end # while (token = input.shift)

      while op_stack.any?
        consume
      end

      unless output.count == 1
        fail ParseError, "Invalid statement"
      end

      output.first
    end # def parse(expr)

    private

    def consume(count=2)
      op_stack.pop if op_stack.last.symbol == ':'
      operator = op_stack.pop
      output.push AST::Node.new(operator, get_args(operator.arity || count))
    end

    def get_args(count)
      Array.new(count) { output.pop }.reverse.compact
    end
  end # class Parser
end # module ReDuxml
require 'symbolic'
require 'dentaku/parser'
require 'dentaku/calculator'
require 'dentaku/ast/identifier'

module Symbolic
  include Comparable
  #need to add support for boolean parameter operations!
  def <=> arg
    operator = caller[0]
    if self.is_a?(Symbolic::Variable) || arg.is_a?(Symbolic::Variable)
      0 if self.value == arg.value
      Variable.new(name: self.value+operator+arg.value)
    else
      self.value <=> arg.value
    end
  end
end

module Resolver_wrapper
  include Dentaku
  include AST

  #have to redefine whole class to override the one method below
  class AST::Arithmetic < Operation
    def initialize(*)
      super
    end

    def type
      :numeric
    end

    def value(context={})
      l = cast(left.value(context))
      r = cast(right.value(context))
      l.public_send(operator, r)
    end

    private

    def cast(value, prefer_integer=true)
      return value unless value.respond_to?(:to_i)
      v = Rational(value)
      v = v.to_i if prefer_integer && v.to_i == v
      v
    end
  end

  class AST::And < Combinator
    def value(context={})
      case
        when left.value === false, right.value === false then false
        when left.is_a?(Parameter), right.value(context) === true then left.value
        when right.is_a?(Parameter), left.value(context) === true then right.value
        else left.value(context) && right.value(context)
      end
    end
  end

  class AST::Or < Combinator
    def value(context={})
      case
        when left.value === true, right.value === true then true
        when left.is_a?(Parameter), right.value(context) === false then left.value
        when right.is_a?(Parameter), left.value(context) === false then right.value
        else left.value(context) || right.value(context)
      end

    end
  end


  class AST::Division < Arithmetic
    def value(context={})
      d = cast(right.value(context), true)
      raise ZeroDivisionError if d.respond_to?(:zero?) && d.zero?
      n = cast(left.value(context))
      cast(n/d)
    end

    def self.precedence
      20
    end
  end

  class Parameter < Identifier
    def value(context={})
      v = context[identifier]
      case v
        when Dentaku::AST::Node
          v.value(context)
        when NilClass
          identifier[0..2] = '!' if identifier.length > 3 && identifier[0..2] == 'not'
          Symbolic::Variable.new :name => identifier
        else
          v
      end
    end
  end

  #overriding Dentaku to use Resolver, not Calculator


  #overriding Calculator to use Simplifier not Parser
  class Resolver < Calculator
    def ast(expression)
      @ast_cache.fetch(expression) {
        Simplifier.new(tokenizer.tokenize(expression)).parse.tap do |node|
          node
          @ast_cache[expression] = node if Dentaku.cache_ast?
        end
      }
    end

    def evaluate(expression, data={})
      rewritten_expr = expression.dup
      rewritten_expr.gsub!('||', 'or')
      rewritten_expr.gsub!('&&', 'and')
      rewritten_expr.gsub!('!false', 'true')
      rewritten_expr.gsub!('!true', 'false')
      rewritten_expr.gsub!('!', 'not')
      evaluate!(rewritten_expr, data)
    end

    def evaluate!(expression, data={})
      results = super(expression, data)
      case
        when results.respond_to?(:to_s) then results.to_s
        when results.respond_to?(:name) then results.name
        else results
      end
    end
  end

  #overriding Parser parse to replace unknown value Identifiers with Parameters
  #the method is huge so had to replace it completely
  class Simplifier < Parser
    def parse
      return Dentaku::AST::Nil.new if input.empty?

      while token = input.shift
        case token.category
          when :numeric
            output.push Dentaku::AST::Numeric.new(token)

          when :logical
            output.push Dentaku::AST::Logical.new(token)

          when :string
            output.push Dentaku::AST::String.new(token)

          when :identifier
            output.push Parameter.new(token)

          when :operator, :comparator, :combinator
            op_class = operation(token)

            if op_class.right_associative?
              while operations.last && operations.last < Dentaku::AST::Operation && op_class.precedence < operations.last.precedence
                consume
              end

              operations.push op_class
            else
              while operations.last && operations.last < Dentaku::AST::Operation && op_class.precedence <= operations.last.precedence
                consume
              end

              operations.push op_class
            end

          when :function
            arities.push 0
            operations.push function(token)

          when :grouping
            case token.value
              when :open
                if input.first && input.first.value == :close
                  input.shift
                  consume(0)
                else
                  operations.push Dentaku::AST::Grouping
                end

              when :close
                while operations.any? && operations.last != Dentaku::AST::Grouping
                  consume
                end

                lparen = operations.pop
                fail "Unbalanced parenthesis" unless lparen == Dentaku::AST::Grouping

                if operations.last && operations.last < Dentaku::AST::Function
                  consume(arities.pop.succ)
                end

              when :comma
                arities[-1] += 1
                while operations.any? && operations.last != Dentaku::AST::Grouping
                  consume
                end

              else
                fail "Unknown grouping token #{ token.value }"
            end

          else
            fail "Not implemented for tokens of category #{ token.category }"
        end
      end

      while operations.any?
        consume
      end

      unless output.count == 1
        fail "Parse error"
      end

      output.first
    end
  end

  def operators current_node
    operators = {}
    if current_node.is_a? Design
      logics = current_node[:logics]
    else
      logics = default_logics
    end
    logics.each do |logic|
      operators[] = @logics[logic]
    end
  end

  def default_logics
    [:string, :boolean, :arithmetic]
  end
end

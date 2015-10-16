require_relative 'symbolic_wrapper'
require 'dentaku'
require 'dentaku/token'
require 'dentaku/ast/identifier'
require 'dentaku/ast/operation'

module Dentaku
  #overriding evaluate to do some rewriting (we can separate this later)
  def self.evaluate(expression, data={})
    #input scrubbing done here
    safe_expression = expression.dup
    banned = {'==' => ' eq ', '!=' => ' ne ', '>=' => ' ge ', '<=' => ' le ', '>' => ' gt ' , '<' => ' lt ',
              '&&' => ' and ', '||' => ' or ', /(!)(?=\w|!)/ => 'not '}
    banned.each do |key, val| safe_expression.gsub!(key, val) end
    reply = calculator.evaluate(safe_expression, data).to_s
    banned.each do |key, val|
      if key == /(!)(?=\w|!)/
        replacement = "!"
        sub_str = val
      else
        replacement = key+' '
        sub_str = val[1..-1]
      end
      reply = reply.gsub!(sub_str, replacement) if reply.include?(sub_str)
    end
    return reply.to_s if reply.respond_to?(:to_s)
  end

  #adding boolean '!'
  class Parser
    def operation(token)
      {
          add:      AST::Addition,
          subtract: AST::Subtraction,
          multiply: AST::Multiplication,
          divide:   AST::Division,
          pow:      AST::Exponentiation,
          negate:   AST::Negation,
          mod:      AST::Modulo,

          lt:       AST::LessThan,
          gt:       AST::GreaterThan,
          le:       AST::LessThanOrEqual,
          ge:       AST::GreaterThanOrEqual,
          ne:       AST::NotEqual,
          eq:       AST::Equal,

          not:      AST::Not_,
          and:      AST::And,
          or:       AST::Or,
      }.fetch(token.value)
    end
  end

  class TokenScanner
    class << self
      #adding replacement symbols because the overrides are too complicated
      def comparator
        new(:comparator, 'le|ge|ne|lt|gt|eq', lambda { |raw| raw.to_sym })
      end

      #adding new combinator '!'
      def combinator
        #added not
        new(:combinator, '(and|or|not)\b', lambda { |raw| raw.strip.downcase.to_sym })
      end
    end
  end

  module AST
    require_relative 'comparable'
    include Symbolic_comparable
    #redefining value to handle unknown value variables
    class Identifier < Node
      #changing NilClass behavior
      def value(context={})
        v = context[identifier]
        case v
          when Node
            v.value(context)
          when NilClass
            #this is where we involve Symbolic to replace Identifier with Variable
            Symbolic::Variable.new(:name => identifier)
          else
            v
        end
      end
    end

    #redef cast to prefer rationals
    class Arithmetic < Operation
      private
      #we prefer rationals
      def cast(value, prefer_integer=true)
        return value unless value.respond_to?(:to_i)
        v = Rational(value)
        v = v.to_i if prefer_integer && v.to_i == v
        v
      end
    end

    class LessThan < Comparator
      def value(context={})
        Symbolic_comparable.lt left.value(context), right.value(context)
      end
    end

    class LessThanOrEqual < Comparator
      def value(context={})
        Symbolic_comparable.le left.value(context), right.value(context)
      end
    end

    class GreaterThan < Comparator
      def value(context={})
        Symbolic_comparable.gt left.value(context), right.value(context)
      end
    end

    class GreaterThanOrEqual < Comparator
      def value(context={})
        Symbolic_comparable.ge left.value(context), right.value(context)
      end
    end

    class NotEqual < Comparator
      def value(context={})
        Symbolic_comparable.ne left.value(context), right.value(context)
      end
    end

    class Equal < Comparator
      def value(context={})
        Symbolic_comparable.eq left.value(context), right.value(context)
      end
    end

    #adding Not Combinator; quite a few overrides because it only has one argument unlike its parent
    class Not_ < Combinator
      attr_reader :node
      def initialize node
        @node = node
        fail "#{ self.class } requires logical operand" unless valid_node?(node)
      end

      def dependencies(context={})
        node.dependencies(context)
      end

      def value(context={})
        Symbolic::Combinands.not(node.value(context))
      end

      def self.arity
        1
      end

      def self.right_associative?
        true
      end

      def self.precedence
        40
      end
    end

    #overriding each Combinator so they use Symbolic's methods
    class And < Combinator
      def value(context={})
        Symbolic::Combinands.and(left.value(context),right.value(context))
      end
    end

    class Or < Combinator
      def value(context={})
        Symbolic::Combinands.or(left.value(context),right.value(context))
      end
    end
  end
end

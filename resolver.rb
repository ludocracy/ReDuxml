require 'dentaku'
require_relative 'symbolic_wrapper'

module Dentaku
  def self.set logic
    @logic = logic
  end

  def self.logic
    @logic
  end
  # overriding evaluate to do some rewriting (we can separate this later)
  def self.evaluate(expression, data={})
    # input scrubbing done here
    safe_expression = expression.dup
    check = logic.aliases(:regexp)
    logic.aliases(:regexp).each_with_index do |symbol, index|
      safe_expression.gsub!(symbol, logic.aliases(:safe)[index])
    end

    # evaluating statement
    reply = calculator.evaluate(safe_expression, data).to_s

    # re-substituting regular symbols for operator "safe" names
    logic.aliases(:safe).each_with_index do |name, index|
      if name == 'not'
        replacement = "!"
        sub_str = "#{name} "
      else
        replacement = "#{logic.aliases(:symbol)[index].to_s} "
        sub_str = " #{name} "
      end
      reply = reply.gsub!(sub_str, replacement) if reply.include?(sub_str)
    end
    raise Exception, "result is not convertible to a string!" unless reply.respond_to?(:to_s)
    reply.to_s
  end

  # loading operators from Logic - these will be used to produce the AST
  class Parser
    def operation(token)
      logic = Dentaku.logic
      op = logic.match_ops(token.value)
      assert op.size == 1
      ast_op = op.aliases(:name)[0]

      # Not has to be aliased here because of naming conflict that i can't figure out
      ast_op = ast_op+'_' if ast_op == 'not'

      # converts operator into module name
      ast_op = "#{ast_op.split(' ').each do |word| word.capitalize! end.join}"

      # if it's a combinator, we're just going to make up the class right here
      AST.const_get ast_op
    end
  end

  # note! we are not dynamically replacing every scanner as they're working fine as they are.
  class TokenScanner
    class << self
      # adding replacement symbols because the overrides are too complicated
      def comparator
        sym = __method__.to_sym
        new(sym, get_search_str(sym), lambda { |raw| raw.to_sym })
      end

      # adding new combinator '!'
      def combinator
        sym = __method__.to_sym
        new(sym, get_search_str(sym), lambda { |raw| raw.strip.downcase.to_sym })
      end

      private
      def get_search_str sym
        a = []
        Dentaku.logic.match_ops(sym).each do |op|
          a << op.aliases(:name)[0]
        end
        "#{a.join('|')})\b"
      end
    end
  end

  module AST
    require_relative 'comparable'
    include Symbolic

    #passing Symbolic_comparable current logic
    class Operation
      Symbolic.set Dentaku.logic
      def initialize(left, right)
        @left  = left
        @right = right
      end
    end

    class Function < Node
      def self.register(name, type, implementation)
        sleep 0
      end
    end

    # redefining value to handle unknown value variables
    class Identifier < Node
      # changing NilClass behavior
      def value(context={})
        v = context[identifier]
        case v
          when Node
            v.value(context)
          when NilClass
            # this is where we involve Symbolic to replace Identifier with Variable
            Symbolic::Variable.new(:name => identifier)
          else
            v
        end
      end
    end

    # redef cast to prefer rationals
    class Arithmetic < Operation
      private
      # we prefer rationals
      def cast(value, prefer_integer=true)
        return value unless value.respond_to?(:to_i)
        v = Rational(value)
        v = v.to_i if prefer_integer && v.to_i == v
        v
      end
    end

    # dynamically creating sub-subclasses of Operation using Operator names and types
    def initialize
      ops = Dentaku.logic.match_ops(:comparator, :combinator, :arithmetic)
      ops.each do |op|
        op_str = op.aliases(:name)[0]
        op_str = op_str+'_' if op_str == 'not'
        op_str = "AST::#{op_str.split(' ').each do |word| word.capitalize! end.join}"

        klass = AST.const_get(op.type.to_s.capitalize)
        operator = Class.new klass do
          # calls actual method using operator safe name
          def value(context={})
            case op.arity
              when 1
                "Symbolic_comparable.#{op.aliases(:safe)}".send node.value(context)
              when 3
                "Symbolic_comparable.#{op.aliases(:safe)}".send left.value(context), middle.value(context), right.value(context)
              else
                "Symbolic_comparable.#{op.aliases(:safe)}".send left.value(context), right.value(context)
            end
          end
        end
        self.const_set(op_str, operator)
      end
    end
  end
end

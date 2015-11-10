require 'dentaku'
require_relative 'comparands'

class Resolver
  @logic
  class << self
    include Dentaku

  end
end

module Dentaku
  def initialize
    # ***********DYNAMICALLY CREATING sub-subclasses of Operation using Operator names and types
    ops = logic.match_ops(:comparator, :combinator, :arithmetic)
    ops.each do |op|
      op.impute(self) do

        # dynamic operator class body
        prepend Symbolic

        attr_reader :operator

        def initialize *args
          @@operator = op # why can't this see outside the block?
          arity = operator.arity
          operands = args.compact
          raise ArgumentError unless arity == operands.size
          # its super would be AST::Comparator/Combinator/Arithmetic
          super *operands
        end

        def self.right_associative?
          arity == 1
        end

        def self.precedence
          operator.precedence
        end

        def self.arity
          operator.arity
        end

        # do we need this??
        def dependencies
          []
        end

        def value(context={})
          # retrieving respective method from Symbolic
          m = Symbolic.method(operator.aliases(:safe)[0])
          case operator.arity
            when 2
              m.call(@left.value(context), @right.value(context))
            when 1
              m.call(@arg.value(context))
            when 3
              m.call(@left.value(context), @middle.value(context), @right.value(context))
            else
              raise "should not happen!"
          end
        end

      end # end dynamic class definition body
      Dentaku::AST.const_set(op_str, op_class)
    end
  end

  # *********** REWRITING HERE *************
  # overriding evaluate to do some rewriting (we can separate this later)
  def self.evaluate(expression, data={})
    # input scrubbing done here
    safe_expression = expression.dup
    logic.match_ops.each do |op|
      if safe_expression[op.regexp]
        replacement = op.aliases(:safe)[0]
        safe_expression.gsub!(op.regexp, " #{replacement} ")
      end
    end

    # evaluating statement
    reply = calculator.evaluate(safe_expression, data).to_s

    # re-substituting regular symbols for operator "safe" names
    logic.aliases(:safe).each do |name|
      if reply.include?(name)
        op = logic.match_ops(name)[0]
        replacement = logic.match_ops(name)[0].symbol.to_s
        reply = reply.gsub!(name, replacement)
      end
    end

    raise Exception, "result is not convertible to a string!" unless reply.respond_to?(:to_s)
    reply.to_s
  end

  extend self

  # loading operators from Logic - these will be used to produce the AST
  class Parser
    def operation(token)
      #taking first operator we get
      op = logic.match_ops(token.value)[0]
      ast_op = op.aliases(:default)[0]
      # Not has to be aliased here because of naming conflict that i can't figure out
      ast_op = ast_op+'_' if ast_op == 'not'

      # converts operator into module name
      ast_op = "#{ast_op.split(' ').each do |word| word.capitalize! end.join}"

      # *******if it's a combinator or comparator DECLARING AST::OPERATOR NODES ******
      AST.const_get ast_op
    end
  end

  class TokenScanner
    attr_reader :category
  end

  class Tokenizer
    # overriding tokenize to add comparator and combinator tokens
    def tokenize(string)
      @nesting = 0
      @tokens  = []
      input    = strip_comments(string.to_s.dup)
      @scanners = TokenScanner.scanners
      register_designos_scanners

      until input.empty?
        raise "parse error at: '#{ input }'" unless @scanners.any? do |scanner|
          scanned, input = scan(input, scanner)
          scanned
        end
      end

      raise "too many opening parentheses" if @nesting > 0

      @tokens
    end

    # replaces existing scanners :comparator and :combinator with our own from @logic
    def register_designos_scanners
      [:comparator, :combinator].each do |sym|
        @scanners.each_with_index do |scanner, index|
          if scanner.category == sym
            @scanners[index] = TokenScanner.new(sym, get_search_str(sym), lambda { |raw| raw.downcase.to_sym })
          end
        end
      end
    end

    private
    #returns regular expression matching operators of type sym
    def get_search_str sym
      a = []
      logic.match_ops(sym).each do |op|
        a << op.aliases(:safe)
      end
      "(#{a.join('|')})\\b"
    end
  end

  module AST

    class Operation < Node
      class << self
        attr_reader :operator
      end

      # because this initialize must be generic for all AST::Operations, and each one uses its own nomenclature
      # attributes vary depending on number of operands
      def initialize(*args)
        case args.size
          when 1 then @arg = args[0]
          when 2 then @left, @right = args[0], args[1]
          when 3 then @left, @middle, @right = args[0], args[1], args[2]
          else @args = args
        end
      end

    end

    class Combinator < Operation
      def initialize(*)
        super
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
  end
end

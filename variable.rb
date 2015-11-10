require 'symbolic'
require_relative 'comparands'
# extending Symbolic to simplify variable expressions and adding combinators that use DesignOS::Operator
module Symbolic

  class Variable
    # unlike include, puts Comparable's methods first before this class's methods in inheritance hierarchy
    prepend Comparands
    # remembers primitive type of last operation; variables can take any value,
    # but once a value is set it cannot be overridden by a value of an incompatible type
    @type

    attr_reader :type

    # Create a new Symbolic::Variable, with optional name, value and proc
    def initialize(options={}, &proc)
      (@name, @value), @proc = options.values_at(:name, :value), proc
      @name = @name.to_s if @name
      c = @value.class
      if @value
        case @value.class
          when Fixnum, Rational then @type = :numeric
          when Float then :float
          when FalseClass, TrueClass then @type = :boolean
          when String then @type = :string
          else @type = @value
        end
      end
    end

    # need this method because we only discover variable's type when operated on
    def set_type sym
      @type = sym
    end

    # this may not be true, but for simplification purposes we must assume it is
    def zero?
      false
    end

    # don't need proc value for now; just need it to return its name
    def value
      name
    end
  end

  def initialize
    @logic.match_ops(:combinator).each do |op|
      op.manifest(parent: self)  do |*args|

      # the following is itself a dynamically created method member of Combinand - see Symbolic::Combinand below
        Combinands.method(method_name).call(*args)

      end
    end
  end

  class Combinands < Expression
    prepend Symbolic

    @operator # should this be a class variable?
    @identity
    @left
    @right

    attr_reader :operator, :identity

    def initialize *args
      #dynamically declare each combinator method and have it call the given simplify method
      Generate_class_methods.def_class_methods(Combinands, logic.aliases(:safe, :combinators)) do |*args|
        @identity = logic.match_op(args[0]).identity
        @operator = args[0]
        simplify *vars
      end

      super *args
    end

    class << self
      attr_reader :logic
      def combinands combinands
        combinands
      end

      # canceling out terms - boolean expressions should always reduce to a single variable or boolean term
      # we merged in not's simplification rule; but maybe all of these need to become separate rules in the logic template?
      def simplify *vars
        if operator.aliases(:safe).include?(:not_)
          # my admittedly hideous solution to making boolean variables negatable
          if vars[0].is_a?(FalseClass || TrueClass)
            return !vars[0]
          elsif vars[0].is_a?(Variable) then s = vars[0].name.dup
          elsif vars[0].is_a?(String) then s = vars[0].dup
          else raise Exception, "cannot boolean-negate a non-boolean expression!"
          end
          s[0..3].include?('not ') ? s[0..3] = '' : s = 'not '+s
          Variable.new name: s, value: :boolean
        end

        l,r,i,ni = vars[0].to_s, vars[1].to_s, identity.to_s, (!identity).to_s
        nl = Combinands.not(l).to_s
        case r
          when i, l then vars[0]
          when ni, nl then ni
          else
            case l
              when i then vars[1]
              when ni then vars[0]
              else "#{l} #{operator} #{r}"
            end
        end
      end # end def simplify

    end # end class << self

    # needs to be rewritten but how??
    def value
      if variables.all?(&:value)
        symbolic.inject(numeric) {|value, (base, coef)| value + base.value * coef.value }
      end
    end

  end # end Combinands

end # end module Symbolic
require 'symbolic'
module Symbolic
  class Variable
    #remembers primitive type of last operation; variables can take any value,
    #but once a value is set it cannot be overridden by a value of an incompatible type
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

    def set_type sym
      @type = sym
    end

    #this may not be true, but for simplification purposes we must assume it is
    def zero?
      false
    end

    #don't need proc value for now; just need it to return its name
    def value
      name
    end
  end

  class Combinands < Expression
    @operator
    @identity
    @left
    @right

    AND_IDENTITY = true
    OR_IDENTITY = false

    class << self
      attr_reader :operator, :identity

      def not var
        #my admittedly hideous solution to making boolean variables negatable
        if var.is_a?(FalseClass || TrueClass) then return !var
        elsif var.is_a?(Variable) then s = var.name.dup
        elsif var.is_a?(String) then s = var.dup
        else raise Exception, "cannot boolean negate a non-boolean expression!"
        end
        s[0..3].include?('not ') ? s[0..3] = '' : s = 'not '+s
        Variable.new name: s, value: :boolean
      end

      def and *vars
        @identity = AND_IDENTITY
        result = simplify *vars
        result
      end

      def or *vars
        @identity = OR_IDENTITY
        simplify *vars
      end

      #canceling out terms - boolean expressions should always reduce to a single variable or boolean term
      def simplify *vars
        s = caller[0]
        @operator = s[/(?!`)\S*(?=')/]
        s.clear
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
      end
    end
  end
end
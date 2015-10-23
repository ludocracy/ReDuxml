require 'symbolic'

# extending Symbolic to simplify variable expressions and adding combinators that use DesignOS::Operator
module Symbolic
  class Variable
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

  # needed to automate creation of operator methods
  class Class
    def self.def_each(*method_names, &block)
      method_names.each do |method_name|
        define_method method_name do |vars|
          instance_exec method_name do block.call vars end
        end
      end
    end
  end

  # this may prove redundant since :logic here already seems to point to Dentaku.logic
  def self.set logic
    @logic = logic
  end

  class Combinands < Expression
    @operator
    @identity
    @left
    @right

    attr_reader :operator, :identity

    class << self
      def initialize
        def_each *logic[:combinators, :safe] do |op_name|
          @identity = logic[op_name].identity
          @operator = op_name
          simplify *vars
        end
      end

      # canceling out terms - boolean expressions should always reduce to a single variable or boolean term
      # we merged in not's simplification rule; but maybe all of these need to become separate rules in the logic template?
      def simplify *vars
        if operator == 'not'
          # my admittedly hideous solution to making boolean variables negatable
          if vars[0].is_a?(FalseClass || TrueClass)
            return !vars[0]
          elsif vars[0].is_a?(Variable) then s = vars[0].name.dup
          elsif vars[0].is_a?(String) then s = vars[0].dup
          else raise Exception, "cannot boolean negate a non-boolean expression!"
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
      end
    end
  end
end
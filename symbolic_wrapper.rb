require 'symbolic'
module Symbolic
  #boolean and/or, etc.

  def <=> arg
    op = caller[0]
    op = op[/(?!`)\w*(?=')/]

    case
      when self == arg then 0
      when self.value
      else
    end
  end

  class Variable
    #this may not be true, but for simplification purposes we must assume it is
    def zero?
      false
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
        s
      end

      def and *vars
        @identity = AND_IDENTITY
        simplify *vars
      end

      def or *vars
        @identity = OR_IDENTITY
        simplify *vars
      end

      #canceling out terms - boolean expressions should always reduce to a single variable or boolean term
      def simplify *vars
        s = caller[0]
        @operator = s[/(?!`)\w*(?=')/]
        s.clear
        l,r,i,ni = vars[0].to_s, vars[1].to_s, identity.to_s, (!identity).to_s
        nl = Combinands.not(l)
        b = (nl == r)
        sleep 0
        case r
          when i, l then l
          when ni, nl then ni
          else
            case l
              when i then r
              when ni then l
              else "#{l} #{operator} #{r}"
            end
        end
      end
    end
  end
end
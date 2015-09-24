require "#{File.dirname(__FILE__)}/expression.rb"
module Symbolic
  require "#{File.dirname(__FILE__)}/expression.rb"
  class Booleans < Expression
    OPERATION = :and
    AND_IDENTITY = true
    OR_IDENTITY = false
    #this boolean's value; only known when operated on, but starts out with AND_IDENTITY i.e. true
    @boolean
    class << self
      def !
        negate
      end

      def not
        negate
      end

      #not working yet!!
      def ternary(true_expr, false_expr)
        if @numeric.nil? and @numeric.is_a? Booleans
          @numeric, @symbolic = unite(true_expr, false_expr)
          #Booleans.new nil,
        else
          if @numeric
            new nil,true_expr.symbolic.first[0] => true_expr.numeric
          else
            new nil, false_expr.symbolic.first[0] => false_expr.numeric
          end
        end
      end

      def and(left, right)
        case
          when right.numeric.nil? then new AND_IDENTITY, right.symbolic.first[0] => right.numeric
          when (right.numeric and left.numeric) then AND_IDENTITY
          else OR_IDENTITY
        end
      end

      def or(left, right)
        case right.numeric
          when AND_IDENTITY then AND_IDENTITY
          when OR_IDENTITY then new(OR_IDENTITY, right.symbolic.first[0] => right.boolean)
          else OR_IDENTITY
        end
      end

      def negate
        case @numeric
          when AND_IDENTITY then @numeric = OR_IDENTITY
          when OR_IDENTITY then @numeric = AND_IDENTITY
          else Variable.new @numeric
        end
      end

      def simplify_expression!(booleans)
        booleans[1].delete_if {|base, coef| coef == false || base == false ? OR_IDENTITY : AND_IDENTITY}
      end

      def simplify(numeric, symbolic)
        if symbolic.empty? #only the numeric portion
          numeric
        elsif numeric == AND_IDENTITY && symbolic.size == 1 #no numeric to add and only one symbolic, so can just return the one base*coefficient
          symbolic.first[1] and symbolic.first[0]
        elsif numeric == OR_IDENTITY  and symbolic.size == 1
          symbolic.first[1] or symbolic.first[0]
        elsif numeric == nil and symbolic.size == 1
          Variable.new "#{symbolic.first[1] and symbolic.first[0]}"
        elsif symbolic.size > 1
          numeric = symbolic.first
          simplify numeric, symbolic
        end
      end
    end

    def value
      @boolean
    end

    def reverse
      self.negate
    end
    def subs(to_replace, replacement=nil)
      if replacement == nil and to_replace.is_a?(Hash)
        super(to_replace)
      else
        @symbolic.inject(@numeric){|m,(base,coefficient)| m + coefficient * base.subs(to_replace, replacement)}
      end
    end

    def == object
      if object.is_a? Booleans
        @numeric == object.numeric || object
      else
        super
      end
    end
  end
end
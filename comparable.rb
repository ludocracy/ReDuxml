module Symbolic_comparable
  include Symbolic

  class << self
    def inverse op
      case op
        when 'eq' then 'ne'
        when 'ne' then 'eq'
        when 'gt' then 'le'
        when 'ge' then 'lt'
        when 'lt' then 'ge'
        when 'le' then 'gt'
        else raise Exception, 'not a valid operator!'
      end
    end

    def reverse op
      case op
        when 'eq' then 'eq'
        when 'ne' then 'ne'
        when 'gt' then 'lt'
        when 'ge' then 'le'
        when 'lt' then 'gt'
        when 'le' then 'ge'
        else raise Exception, 'not a valid operator!'
      end
    end

    def compare left, right
      op = caller[0]
      op = op[/(?!`)\S*(?=')/]
      case
        when !left.is_a?(Symbolic) && !right.is_a?(Symbolic)
          #4 == 4
          left.<=> right
        when left.is_a?(Symbolic) && !right.is_a?(Symbolic)
          #var == 4
          Symbolic::Variable.new(name: "#{left.to_s} #{op} #{right.to_s}", value: :boolean)
        when !left.is_a?(Symbolic) && right.is_a?(Symbolic)
          #4 == var
          Symbolic::Variable.new(name: "#{right.to_s} #{reverse(op)} #{left.to_s}", value: :boolean)
        else
          #var0 == var1
          case
            when left.name == right.name
              #var == var
              0
            when left.type.nil? && right.type.nil?
              #var0 == var1
              Symbolic::Variable.new(name: "#{left.to_s} #{op} #{right.to_s}", value: :boolean)
            when left.type == :boolean, right.type == :boolean, left.type != :numeric && right.type != :numeric
              #!var == var
              nil
            else
              #var*2 == var**-4
              Symbolic::Variable.new(name: "#{left-right} #{reverse(op)} 0", value: boolean)
          end
      end
    end

    def eq left, right
      result = compare(left,right)
      result.is_a?(Symbolic) ? result : result.nil? ? false : result == 0
    end

    def ne left, right
      result = compare(left,right)
      result.is_a?(Symbolic) ? result : result.nil? ? true : result != 0
    end

    def gt left, right
      result = compare(left,right)
      result.is_a?(Symbolic) ? result : result.nil? ? false : result > 0
    end

    def lt left, right
      result = compare(left,right)
      result.is_a?(Symbolic) ? result : result.nil? ? false : result < 0
    end

    def ge left, right
      result = compare(left,right)
      result.is_a?(Symbolic) ? result : result.nil? ? false : result >= 0
    end

    def le left, right
      result = compare(left,right)
      result.is_a?(Symbolic) ? result : result.nil? ? false : result <= 0
    end
  end
end
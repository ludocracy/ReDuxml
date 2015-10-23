#extending Symbolic to simplify variable expressions and adding comparators that use DesignOS::Operators
module Symbolic_comparable
  include Symbolic
  def set logic
    @logic = logic
  end

  class << self
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

    def initialize
      def_each *logic.names[:comparators, :safe] do |op_name|
        result = compare(left,right)
        result.is_a?(Symbolic) ? result : result.nil? ? false : "result #{logic[op_name, :symbol]} 0".send
      end
    end
  end
end
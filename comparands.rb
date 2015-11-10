#extending Symbolic to simplify variable expressions and dynamically adding comparators that use DesignOS::Operators
module Comparands
  def initialize *args
    # ****** DECLARING COMPARATOR METHODS *********
    logic.match_ops(:safe, :comparator).each do |op|
      op.manifest(parent: self) do |left, right|

        # body of the dynamic method
        result = compare(left, right)
        if result.is_a?(Symbolic) then result
        else
          # calling ruby equivalent because result can be successfully compared with 0
          result.nil? ? false : result.method(op.symbol).call(0)
        end

      end
    end
    super *args
  end

  attr_reader :operator

  # 'safe' version of <=> - uses identifiers for operator symbols e.g. :ge => :>= or :ne => :!=
  # distinct in that it handles variable comparands
  def compare left, right
    safe_name = operator.aliases(:safe)[0]
    reverse_name = operator.reverse.aliases(:safe)[0]
    case
      when !left.is_a?(Symbolic) && !right.is_a?(Symbolic)
        #4 == 4
        left.<=> right
      when left.is_a?(Symbolic) && !right.is_a?(Symbolic)
        #var == 4
        Symbolic::Variable.new(name: "#{left.to_s} #{reverse_name} #{right.to_s}", value: :boolean)
      when !left.is_a?(Symbolic) && right.is_a?(Symbolic)
        #4 == var
        Symbolic::Variable.new(name: "#{right.to_s} #{reverse_name} #{left.to_s}", value: :boolean)
      else
        #var0 == var1
        case
          when left.name == right.name
            #var == var
            0
          when left.type.nil? && right.type.nil?
            #var0 == var1
            Symbolic::Variable.new(name: "#{left.to_s} #{safe_name} #{right.to_s}", value: :boolean)
          when left.type == :boolean, right.type == :boolean, left.type != :numeric && right.type != :numeric
            #!var == var
            nil
          else
            #var*2 == var**-4
            Symbolic::Variable.new(name: "#{left-right} #{safe_name} 0", value: boolean)
        end
    end
  end # end compare

end # end Comparable
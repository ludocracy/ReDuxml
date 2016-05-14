require 'symbolic'
require_relative '../../ruby_ext/fixnum'

module Symbolic
  class Variable
    include AST

    def <(obj)
      eql?(obj) ? false : nil
    end

    def >(obj)
      eql?(obj) ? false : nil
    end

    def !=(obj)
      if obj.is_a?(Variable) || obj.is_a?(Numeric)
        return object_id == obj.object_id ? false : nil
      end
      case obj
        when true then new_ast(:!, [self])
        when false then self
        else nil
      end
    end

    def ==(obj)
      if obj.is_a?(Variable) || obj.is_a?(Numeric)
        result = object_id == obj.object_id ? true : nil
        return result
      end
      case obj
        when self then true
        when false then new_ast(:!, obj)
        when true then self
        else nil
      end
    end

    def >=(obj)
      object_id == obj.object_id ? true : nil
    end

    def <=(obj)
      object_id == obj.object_id ? true : nil
    end
  end # class Variable
end # module Symbolic
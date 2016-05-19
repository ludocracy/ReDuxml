require 'symbolic'
require_relative '../ruby_ext/fixnum'
require_relative '../ruby_ext/boolean'

module Symbolic
  class Variable
    include AST

    def and(obj)
      return self if obj.equal?(true) || obj.equal?(self)
      return false if obj.equal?(false)
      nil
    end

    def or(obj)
      return self if obj.equal?(false) || obj.equal?(self)
      return true if obj.equal?(true)
      nil
    end

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

      return !self if obj.equal?(true)
      return self if obj.equal?(false)
      return false if obj.equal?(self)
      nil
    end

    def ==(obj)
      if obj.is_a?(Variable) || obj.is_a?(Numeric)
        result = object_id == obj.object_id ? true : nil
        return result
      end

      return !self if obj.equal?(false)
      return self if obj.equal?(true)
      return true if obj.equal?(self)
      nil
    end

    def >=(obj)
      object_id == obj.object_id ? true : nil
    end

    def <=(obj)
      object_id == obj.object_id ? true : nil
    end
  end # class Variable
end # module Symbolic
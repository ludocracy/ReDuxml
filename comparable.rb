module Comparable
  def <=> arg
    #need to call standard compare if neither object is a Symbolic
    #else apply identity rules
    #glom if more than one term remains
  end

  def == arg
    result = (self <=> arg)
    return result unless result.is_a?(Fixnum)
    result == 0
  end

  def != arg
    result = (self <=> arg)
    return result unless result.is_a?(Fixnum)
    result != 0
  end

  def > arg
    result = (self <=> arg)
    return result unless result.is_a?(Fixnum)
    result > 0
  end

  def < arg
    result = (self <=> arg)
    return result unless result.is_a?(Fixnum)
    result < 0
  end

  def >= arg
    result = (self <=> arg)
    return result unless result.is_a?(Fixnum)
    result >= 0
  end

  def <= arg
    result = (self <=> arg)
    return result unless result.is_a?(Fixnum)
    result <= 0
  end
end
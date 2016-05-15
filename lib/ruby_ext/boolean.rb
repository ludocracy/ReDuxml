require_relative '../../lib/ast_ext/node'

class TrueClass
  def ternary(a, b)
    a
  end

  def and(obj)
    obj
  end

  def or(obj)
    true
  end

  def not
    false
  end
end

class FalseClass
  def ternary(a, b)
    b
  end

  def and(obj)
    false
  end

  def or(obj)
    obj
  end

  def not
    true
  end
end
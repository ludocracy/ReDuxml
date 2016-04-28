module Operator
  def grouping?
    nodes.find(false) do |n|
      n.name == 'match'
    end
  end

  def right_associative?
    nodes.find(false) do |n|
      n.name == 'right_associate'
    end
  end

  def symbol
    nodes.find(self[:id]) do |n|
      n.name == 'symbol'
    end
  end

  def position
    nodes.find(:infix) do |n|
      n.name == 'position'
    end
  end

  def regexp
    nodes.find(self[:id]) do |n|
      %w(regexp symbol ).include?(n.name)
    end
  end

  def arity
    nodes.find(2) do |n|
      n.name == 'arity'
    end
  end
end

module Combinator
  include Operator

  def reduce
    # operate if not parameterized
    # don't if parameterized unless identity
  end

  def coerce(obj)

  end
end

module Comparator
  include Operator

  def reduce

  end
end

module Arithmetic
  include Operator

  def reduce

  end
end

module Operable
  # @return [Boolean]
  def grouping?
    nodes.find do |n|
      return true if n.name == 'match'
    end
    false
  end

  # @return [Boolean]
  def right_associative?
    nodes.find do |n|
      return n.value == 'true' if n.name == 'right_associative'
    end
    false
  end

  # @return [String] literal for operator e.g. '+'
  def symbol
    f = nodes.find() do |n|
      n.name == 'symbol'
    end
    f ? f.text : self[:id]
  end

  # @return [Symbol] :prefix, :infix (default), or :postfix
  def position
    nodes.find do |n|
      return n.text.to_sym if n.name == 'position'
    end
    :infix
  end

  # @return [Regexp] expression to find operator in string
  def regexp
    nodes.find do |n|
      return Regexp.new(n.text) if %w(regexp symbol ).include?(n.name)
    end
    # TODO exception here?
  end

  # @return [Fixnum] number of arguments required
  def arity
    nodes.find do |n|
      return n.text.to_i if n.name == 'arity'
    end
    2
  end
end

module Combinator
  include Operable

  def reduce
    # operate if not parameterized
    # don't if parameterized unless identity
  end

  def coerce(obj)

  end
end

module Comparator
  include Operable

  def reduce

  end
end

module Arithmetic
  include Operable

  def reduce

  end
end

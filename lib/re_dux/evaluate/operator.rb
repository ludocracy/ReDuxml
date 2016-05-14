module Operator
  # @return [Boolean]
  def grouping?
    nodes.find do |n|
      return true if n.name == 'pair'
    end
    false
  end

  def parent=(logic)
    @logic = logic
  end

  # @return [Boolean]
  def right_associative?
    nodes.find do |n|
      return n.text == 'true' if n.name == 'right_associative'
    end
    false
  end

  # @return [String] name of ruby method corresponding to this operator
  def ruby
    nodes.find do |n|
      return n.text if n.name == 'ruby'
    end
    symbol
  end

  # @return [String] literal for operator e.g. '+'
  def symbol
    nodes.find do |n|
      return n.text if n.name == 'symbol'
    end
    raise Exception
  end

  # @return [Symbol] :prefix, :infix (default), or :postfix
  def position
    nodes.find do |n|
      return n.text.to_sym if n.name == 'position'
    end
    :infix
  end

  def reverse
    nodes.find do |n|
      return @logic[n.text] if n.name == 'reverse'
    end
    nil
  end

  def pair
    return nil unless grouping?
    nodes.find do |n|
      return @logic[n.text] if n.name == 'pair'
    end
    raise Exception
  end

  def inverse
    nodes.find do |n|
      return @logic[n.text] if n.name == 'inverse'
    end
    nil
  end

  def to_s
    symbol
  end

  def print
    nodes.find do |n|
      return n.text if n.name == 'print'
    end
    symbol
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

class DoubleStackHash < Hash
  def initialize zero=nil
    super [0, zero] unless zero.nil?
  end

  def [] index
    self[index]
  end

  def []= index, obj
    self.clone.store(index, obj)
  end

  def push obj
    self.clone[last_pos_index+1]=obj
  end

  def last
    self[last_pos_index]
  end

  def first
    self[last_neg_index]
  end

  def unshift obj
    self.clone[last_neg_index-1]=obj
  end

  private
  attr_accessor :left, :right

  def last_neg_index
    keys.size==0 ? -1 : keys.sort.first
  end

  def last_pos_index
    keys.size==0 ? 0 : keys.sort.last
  end
end
class String
  def identifier?
    self.match(/[a-zA-Z][a-zA-Z0-9_]*/).to_s == self
  end
end
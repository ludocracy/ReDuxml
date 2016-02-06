require_relative 'regexp'

class String
  include Enumerable

  def identifier?
    self.match(Regexp.identifier).to_s == self
  end

  def parameterized?
    self.include?('@(')
  end
end
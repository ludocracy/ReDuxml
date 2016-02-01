require_relative 'regexp'

class String
  def identifier?
    self.match(Regexp.identifier).to_s == self
  end
end
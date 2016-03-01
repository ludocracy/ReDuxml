require 'nokogiri'

class Object
  def xml
    begin
      self.respond_to?(:element_children) ? self : Nokogiri::XML(self.to_s).root
    rescue Exception
      nil
    end
  end

  def simple_class
    str = self.class.to_s.split('::').last
    str.split(//).collect do |char|
      char == char.upcase ? "_#{char.downcase!}" : char.downcase
    end.join[1..-1]
  end
end
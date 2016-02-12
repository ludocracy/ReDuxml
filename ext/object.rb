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
    self.class.to_s.split('::').last.downcase
  end
end
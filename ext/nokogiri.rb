require 'nokogiri'

class Nokogiri::XML::Document
  def remove_empty_lines!
    self.xpath("//text()").each do |text|
      text.content = text.content.gsub(/\n(\s*\n)+/,"\n")
    end
    self
  end
end
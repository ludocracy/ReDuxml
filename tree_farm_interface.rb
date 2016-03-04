require_relative 'patterns/template'
require_relative 'ext/nokogiri'

module TreeFarmInterface
  include Patterns

  def initialize file=""
    @kansei_array = []
    plant file if File.exists? file
  end

  def generate type
    current_template.directives(type).each do |directive| harvest! directive end
  end

  def resolve
    grow!
    prune!
    current_template
  end

  def document
    execute!
  end

  def save file_name
    s = current_template.xml_root_node.document.remove_empty_lines!.to_xml.gsub!('><', ">\n<")
    File.write file_name, s
  end

  def base_template
    kansei_array.first
  end

  def current_template
    kansei_array.last
  end

  def plant file
    xml = Nokogiri::XML File.read file
    t = Template.new(xml)
    t.design.each do |node| t.grammar.validate node end
    @kansei_array << t
    base_template
  end
end

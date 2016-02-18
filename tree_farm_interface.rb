require_relative 'patterns/template'

module TreeFarmInterface
  include Patterns

  def resolve
    grow!
    prune!
    current_template
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
    xml = validate(xml) ? xml : wrap(xml)
    @kansei_array << Template.new(xml.root)
    base_template
  end
end

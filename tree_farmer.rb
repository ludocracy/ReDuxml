require_relative 'patterns/template'

module TreeFarmer
  include Patterns
# recursive method that traverses down system design, pruning and instantiating
  def grow current_node=nil
    if current_node.nil?
      kansei = Template.new wrap base_template.design.xml
      @kansei_array << kansei
      grow kansei.design
    else
      params_stacked = update_params! current_node
      resolve_parameterized! current_node
      children = instantiate! current_node
      children.each do |child|
        peek(child) ? grow(child) : current_node.remove(child)
      end
      @parameters_stack.pop if params_stacked
    end
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

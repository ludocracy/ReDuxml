require File.expand_path(File.dirname(__FILE__) + '/../../ruby_ext/string')

module Parameterization
  def parameterized_xml_nodes
    return unless type=='design' || descended_from?(:design)
    xml_nodes = xml_root_node.attribute_nodes
    xml_root_node.children.each do |child|
      if child.is_a?(Nokogiri::XML::Node) && child.text?
        xml_nodes << child
        break
      end
    end
    a = []
    xml_nodes.collect do |xml_node|
      a << xml_node if xml_node.content.parameterized?
    end
    a
  end

  def if?
    return true unless (if_str = xml_root_node[:if])
    if_str.parameterized? || if_str == 'true' ? true : false
  end

  def if= condition
    # check for valid conditional
    change_attr_value :if, condition
  end
end

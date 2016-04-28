require File.expand_path(File.dirname(__FILE__) + '/../../ruby_ext/string')

# methods to extend Dux::Object with methods needed to process parameterized XML content
module Parameterization
  # returns the first ancestor of this object that is of type Dux::Instance
  def instance
    parentage.each do |ancestor| return ancestor if ancestor.respond_to?(:params) end
    nil
  end

  # returns detached copy of all descendants of this node
  def detached_subtree_copy
    new_node = detached_copy
    children.each do |child|
      new_node << child.detached_subtree_copy
    end
    new_node
  end

  # returns just the xml element head with attributes, without any children
  def stub
    x = xml.dup
    x.element_children.remove
    self.class.new x
  end

  alias_method :detached_copy, :stub

  # returns xml_nodes within this node that are parameterized
  def parameterized_xml_nodes
    return unless type=='design' || descended_from?(:design)
    xml_nodes = xml.attribute_nodes
    xml.children.each do |child|
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

  # returns true if self[:if] is true or indeterminate (because condition is currently parameterized)
  # returns false otherwise i.e. this node does not exist in this design build
  def if?
    return true unless (if_str = xml[:if])
    if_str.parameterized? || if_str == 'true' ? true : false
  end

  # changes condition of this object's existence
  def if= condition
    # check for valid conditional
    change_attr_value :if, condition
  end
end # module Parameterization

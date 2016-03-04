# components consist of components and never overlap. therefore a general tree.rb structure is perfect
# for representing component structures and also works perfectly with XML
# however, DesignOS needs to be able to traverse concreteward and abstractward
# and there are up to as many of each as there are views; change timestamps are a view (concrete if after a change, abstract if before);
# for example: when a parameter is set, the resulting design is a concrete child
# if that parameter value is overridden by a subtemplate, that produces a concrete grandchild
# therefore, every node in this new type of tree.rb is also a member of a hash of arrays - one hash for each query, and
# view hashes are only constructed upon query except for those needed by DesignOS to perform
#
# changes made to Components are made to both the XML node and data node simultaneously
# in order to provide real-time feedback to XML editor
# could add switch to turn this off

require_relative '../../ext/xml'
require_relative '../../ext/tree'
require_relative '../../ext/object'
require_relative 'interface'
require_relative 'guts'

module Components
  # Components are equivalent to objects in OOP; they are implemented as XML structures that have no branching except for the Component's children.
  # in addition they are Kansei objects existing along two concrete/abstract dimensions, one for views, the other for builds
  # each Kansei object is also a Tree::TreeNode
  class Component < Tree::TreeNode
    include Components::Interface

    @xml_root_node
    @xml_cursor

    attr_reader :children, :children_hash, :xml_root_node

    alias_method :id, :name

    def initialize xml_node, args={}
      @reserved_word_array = args[:reserved] || []
      @xml_root_node = @xml_cursor = xml_node.nil? ? class_to_xml(args) : xml_node.xml
      xml_root_node[:id] ||= xml_root_node.name+object_id.to_s
      # must happen before traverse to have @children/@children_hash available
      super xml_root_node[:id], xml_root_node.content
      # traverse and load Component from xml
      traverse_xml exec_methods %w(do_nothing init_reserved init_generic)
    end # end of Component::initialize(xml_node, args={})

    private
    include Components::Guts

    attr_reader :xml_cursor, :reserved_word_array
  end # end of class Component

end # end of module Components
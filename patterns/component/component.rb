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

require 'tree/tree_deps'
require_relative '../../ext/object'
require_relative '../../ext/tree'
require_relative 'interface'
require_relative 'guts'

module Components
  # Components are equivalent to objects in OOP; they are implemented as XML structures that have no branching except for the Component's children.
  # in addition they are Kansei objects existing along two concrete/abstract dimensions, one for views, the other for builds
  # each Kansei object is also a Tree::TreeNode
  class Component < Tree::TreeNode
    include Components::Interface
    # hash of builds where keys are parameter settings and values are kansei siblings of this component
    @kanseis
    @visible
    @xml_root_node

    # tracks all content nodes that contain parameterized expressions for quick retrieval and resolution
    # keys are the nodes themselves, values are the strings that contain the parameter expressions
    @parameterized_nodes
    # tracks where to add children; on initializing traverse, leave it at the last singleton child
    @xml_cursor

    # array of words that indicate reserved classes
    @attributes

    attr_reader :children, :children_hash, :xml_root_node, :kanseis, :abstraction

    attr_accessor :parameterized_nodes

    # creating new Component from XML node (from file) or input in the form of XML string
    def initialize xml_node, args={}
      raise ArgumentError unless @xml_root_node = xml_node.xml
      @abstraction = nil
      @kanseis = Hash.new
      @parameterized_nodes = []
      @reserved_word_array = args[:reserved] || []

      @xml_cursor ||= xml_root_node

      # must happen before traverse to have @children/@children_hash available
      super @xml_root_node
      # traverse and load Component from xml
      traverse_xml load_methods %w(load_parameterized_nodes init_reserved init_generic)
    end # end of Component::initialize(xml_node, args={})

    private
    include Components::Guts

    attr_reader :xml_cursor
  end # end of class Component

end # end of module Components
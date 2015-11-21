# the component is the base of every object in DesignOS and any designs produced in it.
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

require_relative 'ext/tree'
require 'tree/tree_deps'
require 'nokogiri'

# my own stuff
module Patterns
  # Components are equivalent to objects in OOP; they are implemented as XML structures that have no branching except for the Component's children.
  # in addition they are Kansei objects existing along two concrete/abstract dimensions, one for views, the other for builds
  # each Kansei object is also a Tree::TreeNode
  # disabling kansei features until we can architect it properly

  class Component < Tree::TreeNode
    # HEY HEY!!! pull out some of these attributes and make them structs!! some possible groupings:
    # xml_related, conditionals, inherent properties? or perhaps by phase - when they're accessed? both?
    # id or name identify this Component uniquely among its neighbors (template for @id, immediate family for @name)
    @id
    # points to the XML element root of this Component
    @xml_root_node
    # hash of viewings where keys are view settings and values are kansei siblings of this component
    @views = []
    # hash of builds where keys are parameter settings and values are kansei siblings of this component
    @builds = {}
    # array of words that indicate reserved classes
    @reserved_word_array = []
    # hash of attribute name keys and attribute node values derived from XML attributes and leaf singletons
    # hash values are of type Nokogiri::XML:Attr
    @attributes = {}
    # tracks where to add children; on initializing traverse, leave it at the last singleton child
    @xml_cursor
    # lists all views that can see this Component
    @visible = []
    # array of Nokogiri::XML::Attr whose values must all be true for this Component to build
    @if = []
    # tracks all content nodes that contain parameterized expressions for quick retrieval and resolution
    # keys are the nodes themselves, values are the strings that contain the parameter expressions
    @parameterized_nodes = {}
    # description of what this component represents in a design; can contain XML e.g. DITA content
    # at its most basic it is the comment on the subclass of Component or annotation in the schema rules
    @@description

    attr_reader :id, :builds, :views, :children, :children_hash, :parameterized_nodes, :xml_cursor, :if

    # HEY HEY!!! need to group these into modules and pull them out!

    # shortcut
    def xml
      @xml_root_node
    end

    def to_s
      @xml_root_node.to_s
    end

    def collect_changes change
      cur = self.parent
      while cur
        if cur.is_a? Template
          cur.history.register_with_owner change
        end
        cur = cur.parent
      end
    end

    def summarize
      content = ""
      if @children.size != 0
        content = "children: "
        @children.each do |child|
          content << "'#{child.name}' "
        end
      else
        content = "content: #{self.content}"
      end
      puts "Component '#{name}' #{content}"
    end

    # creating new Component from XML node (from file) or input in the form of XML string
    def initialize xml_node, args = {}
      unless xml_node.element?
        generate_new_xml args
      end
      @xml_cursor = xml_node
      @xml_root_node = @xml_cursor
      @views = Hash.new
      @builds = Hash.new
      @if = []
      @visible = ['admin']
      @parameterized_nodes = Hash.new
      @attributes = Hash.new
      @reserved_word_array ||= []


      # must happen before traverse to have @children/@children_hash available
      super(@xml_root_node)
      # traverse and load Component from xml
      collect_changes traverse_xml load_methods %w(load_attributes init_reserved chase_tail init_generic)
    end # end of Component::initialize(xml_node, args={})

    # loads methods to run during initialize from a hash
    def load_methods method_names
      method_hash = {}
      index = 0
      %w(top reserved traverse child).each do |key|
        method_name = method_names[index]
        if method_name
          our_method = method(method_names[index].to_sym)
        else
          our_method = method(:do_nothing)
        end
        method_hash[key.to_sym] = our_method
        index += 1
      end
      method_hash
    end

    # needed because i have to call a method and it has to have an argument
    def do_nothing arg = nil
      # this is silly
    end

    # used to create new XML for a new Component
    def generate_new_xml args = {}
      element_name = self.class.to_s.downcase!
      element_name[/.*(?:(::))/] = ''
      @xml_root_node = @xml_cursor = element(element_name,(args[:content]))
    end

    # should describe itself in a string
    def generate_descr

    end

    # run by initialize
    def traverse_xml method_hash
      method_hash[:top].call
      @xml_cursor.element_children.each do |child|
        if @reserved_word_array.include? child.name
          method_hash[:reserved].call child
        else
          if @xml_cursor.element_children.size == 1
            method_hash[:traverse].call child
          else
            method_hash[:child].call child
          end
        end
      end
    end

    # called by method hash when traversing down a Component's trailing XML descendants; its 'tail'
    def chase_tail child
      @xml_cursor = child
    end

    # adds leaf content as attribute; element name as key
    def load_content_if_leaf
      @attributes[@xml_cursor.name] = @xml_cursor.content if @xml_cursor.element_children.size == 0
    end

    # child has a ruby class of its own
    def init_reserved child
      child_class = Object::const_get("Patterns::#{child.name.capitalize}")
      self << child_class.new(child)
    end

    # child is just XML - wrap it
    def init_generic child
      self << Component.new(child)
    end

    #takes an xml node's attributes and adds them to the Component's @attributes hash
    def load_attributes
      load_content_if_leaf
      @xml_cursor.attribute_nodes.each do |attr|
        key = attr.name.to_sym
        case key
          when :id || :name
            @id = attr.value
          when :visible
            @visible << " #{attr.value}"
          when :if
            @if << attr
          else
            @attributes[attr.name.to_sym] = attr.value
        end
      end
      if @id.nil?
        @id = self.object_id.to_s
      end
    end

    # traverses this Component's xml (and not children's) for parameterized content nodes
    def get_parameterized_xml_nodes
      @parameterized_nodes = {}
      traverse_xml load_methods ['find_parameterized_nodes', nil, 'chase_tail', nil]
      @parameterized_nodes
    end

    # looks through all attributes for parameter expressions
    def find_parameterized_nodes
      @if.each do |condition_node|
        add_if_parameterized condition_node
      end
      @attributes.each do |attr|
        add_if_parameterized attr
      end
    end

    # if a given attribute value is parameterized, add to hash with attribute node itself as key
    def add_if_parameterized attr
      if attr.respond_to(:value)
        value = attr.value
      else
        value = attr[1]
      end
      @parameterized_nodes[attr] = value if value.include? '@('
    end


    def view view_hash
      if reconcile view_hash, @visible
        # @views[view_hash] = @cursor.dup
      end
    end

    def reconcile view_hash, visible
      visible.split(' ').each do |view|
        true if view_hash.include? view
      end
      false
    end

    # finds first near match child
    def find_child child_pattern
      #attempting to match by name
      @children.each do |cur_child|
        return cur_child if cur_child.name == child_pattern
      end
      #attempting to use pattern as index
      @children[child_pattern]
    rescue TypeError
      #attempting to use pattern as key
      @children_hash[child_pattern]
    end

    # a slightly safer way to get an attribute's final value (read only)
    def get_attr_val attr
      @attributes[attr]
    end

    def children?
      @children.size.to_s
    end

    # overriding TreeNode::content to point to XML head's content
    def content
      xml.content
    end

    # initializes component attributes if empty
    def []= attr, *vals
      @attributes[attr] ||= vals.join ' '
    end

    def [] attr
      get_attr_val attr
    end

    # extending TreeNode's add child to link up XML if for new node
    def << component_child
      if component_child.xml.parent.nil?
        @xml_cursor << component_child.xml
        super component_child
        throw :change, Insert.new(nil, {ref: component_child})
      end
      super component_child
    end

    # creates new XML element
    def element name, content = nil
      doc = @xml_doc || @xml_root_node.document
      new_element = Nokogiri::XML::Element.new name, doc
      if content
        new_element.content = content
      end
      new_element
    end


    private :element, :load_attributes, :init_reserved, :init_generic, :chase_tail, :traverse_xml, :find_parameterized_nodes, :add_if_parameterized, :reconcile, :generate_new_xml, :load_content_if_leaf, :collect_changes, :load_methods
  end # end of class Component

end # end of module Patterns
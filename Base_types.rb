#the component is the base of every object in DesignOS and any designs produced in it.
#components consist of components and never overlap. therefore a general tree structure is perfect
#for representing component structures and also works perfectly with XML
#however, DesignOS needs to be able to traverse concreteward and abstractward
#and there are up to as many of each as there are views; change timestamps are a view (concrete if after a change, abstract if before);
#for example: when a parameter is set, the resulting design is a concrete child
#if that parameter value is overridden by a subtemplate, that produces a concrete grandchild
#therefore, every node in this new type of tree is also a member of a hash of arrays - one hash for each query, and
#view hashes are only constructed upon query except for those needed by DesignOS to perform
#
#changes made to Components are made to both the XML node and data node simultaneously
#in order to provide real-time feedback to XML editor
#could add switch to turn this off
module Base_types
  #authentication gem
  #require 'devise'
  #XML parsing and manipulation
  require 'nokogiri'
  require_relative 'Builder'
  include Builder

  #Components are equivalent to objects in OOP; they are implemented as XML structures that have no branching except for the Component's children.
  #in addition they are Kansei objects existing along two concrete/abstract dimensions, one for views, the other for builds
  #each Kansei object is also a Tree::TreeNode
  #disabling kansei features until we can architect it properly

  class Component < Tree::TreeNode
    #id or name identify this Component uniquely among its neighbors (template for @id, immediate family for @name)
    @id
    #points to the XML root of this Component
    @xml_root_node = Nokogiri::XML::Element
    #hash of viewings where keys are view settings and values are kansei siblings of this component
    @views = []
    #hash of builds where keys are parameter settings and values are kansei siblings of this component
    @builds = {}
    #array of words that indicate reserved classes
    @reserved_word_array = []
    #hash of attribute name keys and attribute node values derived from XML attributes and leaf singletons
    #hash values are of type Nokogiri::XML:Attr
    @attributes = {}
    #tracks where to add children; on initializing traverse, leave it at the last singleton child
    @xml_cursor
    #lists all views that can see this Component
    @visible = []
    #array of Nokogiri::XML::Attr whose values must all be true for this Component to build
    @if = []
    #tracks all content nodes that contain parameterized expressions for quick retrieval and resolution
    #keys are the nodes themselves, values are the strings that contain the parameter expressions
    @parameterized_nodes = {}
    #description of what this component represents in a design; can contain XML e.g. DITA content
    #at its most basic it is the comment on the subclass of Component or annotation in the schema rules
    @@description

    #shortcut
    def xml
      @xml_root_node
    end

    #so we don't get XML gobbledygook
    def to_s
      puts "root element: #{element}; children:"
      i = 0
      @children.each do |child|
        puts "#{i}: #{child.content.name}"
        i += 1
      end
    end

    #creating Component by either loading given xml_node, or
    #if args present, add new Component to given parent xml_node initialized with given args
    def initialize xml_node, args = {}
      @views = Hash.new
      @builds = Hash.new
      @if = []
      @visible = ['admin']
      @parameterized_nodes = Hash.new
      @attributes = Hash.new
      if args[:name]
        init_load_xml xml_node
      else
        init_create_xml xml_root_node, args
      end
    end

    #creates new Component out of given xml node; traverses down singletons and includes them also;
    #loads attributes and singleton contents into single flattened hash
    def init_load_xml xml_root_node
      @xml_cursor = @xml_root_node = xml_root_node
      @reserved_word_array ||= []
      super(self.object_id.to_s, @xml_root_node)

      loading_methods = {born: lambda{load_attributes}, child: lambda{load_child}, died: lambda{load_leaf_content}}
      traverse_xml @xml_cursor, loading_methods

      @id ||= self.object_id.to_s
    end

    #creates new Component and adds to xml_parent_node, using args to initialize values
    #cannot create more than two levels of XML; all attributes are given to the root element
    def init_create_xml xml_parent_node, args
      xml_parent_node << @xml_cursor = @xml_root_node = Nokogiri::XML::Element.new(args[:root], args[:parent].document)
      args[:attributes].each do |attr|
        @xml_root_node[attr.key] = attr.value
      end
      args[:children].each do |child_info|
        @xml_root_node << child_node = Nokogiri::XML::Element.new(child_info.key, @xml_root_node.document)
        child_node.content = child_info.value
        self << Component.new(child_node)
      end
      if @children.size == 1
        @xml_cursor = @xml_cursor.element_children[0]
      end
    end

    #recurses from a given xml element; give it various tasks using method hash
    def traverse_xml xml_cursor, method_hash
      @xml_cursor = xml_cursor
      method_hash[:born].call
      if xml_cursor.element_children.size == 0
        method_hash[:died].call
      end
      if xml_cursor.element_children.size == 1
        traverse_xml xml_cursor.element_children[0], method_hash
      else
        xml_cursor.element_children.each do |child_xml_node|
          @xml_cursor = child_xml_node
          method_hash[:child].call
        end
      end
      @xml_cursor = xml_cursor
    end

    #adds leaf content as attribute; element name as key
    def load_leaf_content
      @attributes[@xml_cursor.name] = @xml_cursor.content
    end

    #loads sub components of this component from xml
    def load_child
      child_name = @xml_cursor.name
      if @reserved_word_array.include? child_name
        child_class = Object::const_get(child_name.capitalize)
        self << child_class.new(@xml_cursor)
      else
        self << Component.new(@xml_cursor)
      end
    end

    def load_attributes
      @xml_cursor.attribute_nodes.each do |attr|
        case attr.name
          when 'id' || 'name'
            @id = attr.value
          when 'visible'
            @visible << " #{attr.value}"
          when 'if'
            @if << attr
          else
            @attributes[attr.name] = attr
        end
      end
    end

    #traverses this Component's xml (and not children's) for parameterized content nodes
    def get_parameterized_xml_nodes
      @parameterized_nodes = nil
      resolve_methods = {born: lambda{find_parameterized_nodes}, child: lambda{@xml_cursor = nil}}
      traverse_xml @xml_root_node, resolve_methods
      @parameterized_nodes
    end

    #looks through all attributes for parameter expressions
    def find_parameterized_nodes
      @if.each do |condition_node|
        add_if_parameterized condition_node
      end
      @attributes.values.each do |attr|
        add_if_parameterized attr
      end
    end

    #if a given attribute value is parameterized, add to hash with attribute node itself as key
    def add_if_parameterized attr
      @parameterized_nodes[condition_node] = condition_node.value if condition_node.value.include? '@('
    end


    def view view_hash
      if reconcile view_hash, @visible
        @views[view_hash] = @cursor.dup
      end
    end

    def reconcile view_hash, visible
      visible.split(' ').each do |view|
        true if view_hash.include? view
      end
      false
    end

    def find_child child
      @children.each do |cur_child|
        return cur_child if cur_child.element == child
      end
      @children[child]
    rescue TypeError
      @children_hash[child]
    end

    def get_attr_val attr
      @attributes[attr].value
    end

    def element
      @xml_root_node.name
    end

    def inspect
      children_names = ''
      @children.each do |child|
        children_names << "'#{child.element}' "
      end
      puts "Component '#{element}' with children: #{children_names}"
    end

    #redefining TreeNode::name as Component::id
    alias_method :id, :name

    def children?
      @children.size.to_s
    end

    #overriding TreeNode::content to point to XML head's content
    def content
      xml.content
    end

    #initializes component attributes if empty
    def []= attr, *vals
      @attributes[attr] ||= vals.join ' '
    end

    def [] attr
      get_attr_val attr
    end

    attr_reader :id, :builds, :views, :children, :children_hash, :parameterized_nodes, :xml_cursor

    private :load_attributes, :traverse_xml, :load_child, :find_parameterized_nodes, :add_if_parameterized, :reconcile
  end

  #template Owners class - contains Owner Hash
  class Owners < Component
    def initialize xml_node
      @reserved_word_array = 'owner'
      super xml_node
    end
  end

  #template Owner class
  class Owner < Component
    def initialize xml_node
      super xml_node
    end
  end

  #Templates are components that constitute a distinct technology
  #They must have owners and always record sub-component changes
  #Element names reserved by the template's schema rules become constructors for sub-components
  class Template < Component
    def initialize template_root_node
      @reserved_word_arrays = %w(owners history design)
      super template_root_node
    end

    def history
      find_child 'history'
    end
  end

  #all templates have histories and objects that have been queried
  class History < Component
    def initialize xml_node
      @reserved_word_array = %w(insert remove edit error correction instantiate move undo)
      super xml_node
    end

    def size
      @children.size
    end

    def change_hash
      @children_hash
    end

    def get_changes arg
      #handle cases for searches by: date, date range, owner, type, target,
    end
  end

  #individual change; not to be used, only for subclassing
  class Change < Component
    def initialize xml_node
      super xml_node
    end
  end

  #Component instantiated; holds pointers to Edits to parameter values if redefined for this instance
  #holds pointer to antecedent; generates fresh ID for instance; adds as new child to template
  class Instantiate < Change
    def initialize xml_node
      super xml_node
    end
  end

  #error found during build inspection process (syntax errors) or during general inspection - saved to file if uncorrected on commit
  #points to rule violated and/or syntax marker and previous error in exception stack
  class Error < Change
    def initialize xml_node
      super xml_node
    end
  end

  #build-time, inspection or committed error correction - points to error object
  #also points to change object that precipitated this one
  #(could be another correction or other change-type other than Error or Instantiate)
  class Correction < Change
    def initialize xml_node
      super xml_node
    end
  end

  #removal of node can occur when building design from de-instantiation (@if == false)
  #when inspecting from a given perspective, or from user input when editing
  class Remove < Change
    def initialize xml_node
      super xml_node
    end
  end

  #insertion of node can occur when building design from instantiation
  #after inspector reports changes (when historian inserts changes into history)
  #and from user input when editing
  class Insert < Change
    def initialize xml_node
      super xml_node
    end
  end

  class Move < Change
    def initialize xml_node
      super xml_node
    end
  end

  #change to element content or attribute value, essentially the actual content of the Component has changed
  #this can occur from owner input when editing
  #or initiated by Builder when dealing with parameters (and nothing else)
  class Edit < Change
    #string containing new content
    @new_content
    #string containing old content (if content is XML, string can be converted to XML)
    @old_content
    #xpath to changed element
    @xpath
    #string if empty content change was to element; if non-empty is name of attribute value changed
    @attributeOrNo
    @previous
    @next


    def initialize xml_node
      super xml_node
    end

    def old_content

    end
  end

  class Undo < Change
    def initialize xml_node
      super xml_node
    end
  end

  #instances are copies (dclones) or aliases (clones) of a given Component; if copies, they get Instances of the children also
  #when used to wrap a Component or set of Components, allows use of locally-namespaced parameters
  #when empty but given a target Component, creates copy and added as new child or creates alias and added as mirror child
  #wrapper is removed after build; aliases
  class Instance < Component
    #instances can expect reserved component element names AND parameter assignment hash
    def initialize xml_node
      @reserved_word_array = %w(parameters array instance)
      super xml_node
    end

    def get_param_hash
      parameters = find_child'parameters'
      if parameters
        parameters.children_hash
      else
        {}
      end
    end

    def get_param_val arg
      get_parameter_hash[arg].value
    end
  end

  #links function as aliases of a given Component; essentially they are the same object but in target location and location of Link object
  #actually implemented by redirecting pointers to target; Link Components must never have children!! any children added will be added to target!!
  class Link < Component
    def initialize xml_node
      @reserved_word_array = []
      super xml_node
    end

    def link?
      true
    end
  end

  #part of the template file that actually contains the design or content
  #specifies logics allowed within itself
  class Design < Instance
    def initialize xml_node
      super xml_node
    end
  end

  #basic means of creating patterned clones of a component; can contain a design or instances
  class Array < Instance
    def initialize xml_node
      super xml_node
    end

    def size
      get_attr_val 'size'
    end
  end

  #container for multiple parameters
  class Parameters < Component
    @reserved_word_array = 'parameter'
    def initialize xml_node
      super xml_node
    end
  end

  #specialization of Component holds parameter name, value and description
  #also, during Build, its abstracts and concretes track parameter value overrides
  class Parameter < Component
    def initialize xml_node
      super xml_node
    end

    def value
      self['value']
    end
  end
end
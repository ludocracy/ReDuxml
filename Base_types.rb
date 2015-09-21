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
  require 'rubytree'
  include Tree
  require_relative 'debug'
  include Debug

  #Components are equivalent to objects in OOP; they are implemented as XML structures that have no branching except for the Component's children.
  #in addition they are Kansei objects existing along two concrete/abstract dimensions, one for views, the other for builds
  #each Kansei object is also a Tree::TreeNode
  #disabling kansei features until we can architect it properly

  class Component < Tree::TreeNode
    #pull out some of these attributes and make them subclasses - like static vs dynamic members?
    #id or name identify this Component uniquely among its neighbors (template for @id, immediate family for @name)
    @id
    #points to the XML element root of this Component
    @xml_root_node
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

    def root_name
      @xml_root_node.name
    end

    def collect_changes change
      cur = self.parent
      while cur
        if cur.is_a? Template
          cur.history.register change
        end
        cur = cur.parent
      end
    end

    def summarize
      content = ""
      if @children.size != 0
        content = "children: "
        @children.each do |child|
          content << "'#{child.root_name}' "
        end
      else
        content = "content: #{self.content}"
      end
      puts "Component '#{root_name}' #{content}"
    end

    #creating new Component from XML node (from file) or input in the form of XML string
    def initialize xml_node, args = {}
      @xml_cursor = xml_node
      if @xml_cursor.nil?
        generate_new_xml args
      end
      @xml_root_node = @xml_cursor
      @views = Hash.new
      @builds = Hash.new
      @if = []
      @visible = ['admin']
      @parameterized_nodes = Hash.new
      @attributes = Hash.new
      @reserved_word_array ||= []

      #must happen before traverse to have @children/@children_hash available
      super(self.object_id.to_s, @xml_root_node)

      #loading methods because traverse is used by many different processes
      loading_methods = {born: lambda{load_attributes}, child: lambda{load_sibling}, grow: lambda{load_child}, died: lambda{load_leaf_content}}
      #traverse and load Component from xml
      collect_changes traverse_xml loading_methods
    end

    def generate_new_xml args = {}
      @xml_cursor.element self.class.to_s, args[:content]
    end

    def generate_descr

    end

    #recurses from a given xml element; give it various tasks using method hash
    def traverse_xml method_hash
      d if @xml_cursor.name == 'version'
      d if @xml_cursor.name == "description"
      method_hash[:born].call
      if @xml_cursor.element_children.size == 0
        method_hash[:died].call
      end
      if @xml_cursor.element_children.size == 1
        @xml_cursor = @xml_cursor.element_children[0]
        method_hash[:grow].call
        traverse_xml method_hash
      else
        last_change = nil
        @xml_cursor.element_children.each do |child_xml_node|
          @xml_cursor = child_xml_node
          new_change = catch :change do
            method_hash[:child].call
          end
          if new_change
            d "how did we get here??"
            if last_change.nil?
              last_change = new_change
            else
              last_change << new_change
            end
          end
        end
        #popping cursor back up to parent so we don't insert new children as grandchildren!
        @xml_cursor = @xml_cursor.parent if @xml_cursor.parent.element_children.size > 1
        last_change
      end
    end

    #adds leaf content as attribute; element name as key
    def load_leaf_content
      @attributes[@xml_cursor.name] = @xml_cursor.content
    end

    #loads sub components of this component from xml
    def load_sibling
      unless load_child
        init_generic_child
      end
    end

    def load_child
      if @reserved_word_array.include? @xml_cursor.name
        init_reserved_child
        true
      else
        false
      end
    end

    def init_reserved_child
      child_class = Object::const_get("Base_types::#{@xml_cursor.name.capitalize}")
      self << child_class.new(@xml_cursor)
    end

    def init_generic_child
      self << Component.new(@xml_cursor)
    end

    def load_attributes
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
            @attributes[attr.name.to_sym] = attr
        end
      end
      if @id.nil?
        @id = self.object_id.to_s
      end
    end

    #traverses this Component's xml (and not children's) for parameterized content nodes
    def get_parameterized_xml_nodes
      @parameterized_nodes = nil
      resolve_methods = {born: lambda{find_parameterized_nodes}, child: lambda{@xml_cursor = nil}}
      traverse_xml resolve_methods
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
      @parameterized_nodes[attr] = attr.value if attr.value.include? '@('
    end


    def view view_hash
      if reconcile view_hash, @visible
        #@views[view_hash] = @cursor.dup
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
        return cur_child if cur_child.root_name == child
      end
      @children[child]
    rescue TypeError
      @children_hash[child]
    end

    def get_attr_val attr
      @attributes[attr].value
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

    #extending TreeNode's add child to link up XML if for new node
    def << child_component
      d "adding #{child_component.root_name} to #{self.root_name}"
      if child_component.xml.parent.nil?
        @xml_cursor << child_component.xml
        super child_component
        throw :change, Insert.new(nil, {ref: child_component})
      end
      super child_component
      #popping cursor back up to parent so we don't insert new children as grandchildren!
      @xml_cursor = @xml_cursor.parent
    end

    def element name, content = nil
      new_element = Nokogiri::XML::Element.new name, @xml_cursor.document
      if content
        new_element.content = content
      end
      new_element
    end

    attr_reader :id, :builds, :views, :children, :children_hash, :parameterized_nodes, :xml_cursor

    private :element, :load_attributes, :traverse_xml, :load_child, :find_parameterized_nodes, :add_if_parameterized, :reconcile, :generate_new_xml
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
    def initialize xml_node, args ={}
      super xml_node
    end

    def generate_new_xml args

    end
  end

  #Templates are components that constitute a distinct technology
  #They must have owners and always record sub-component changes
  #Element names reserved by the template's schema rules become constructors for sub-components
  class Template < Component
    #points to actual xml document. @xml_root_node points to the root element.
    @xml_doc
    #users or processes that created this template
    @owners

    def initialize template_root_node, args = {}
      @reserved_word_array = %w(owners history design)
      #creating new template
      super template_root_node, args
    end

    def history
      find_child 'history'
    end

    def owners
      find_child 'owners'
    end

    def generate_new_xml args = {}
      @xml_doc = Nokogiri::XML::Document.new
      @xml_doc << @xml_root_node = super
      @xml_root_node['visible'] = args[:owner].object_id.to_s
    end
  end

  #all templates have histories and objects that have been queried
  #might need to wrap in module to namespace?
  class History < Component
    def initialize xml_node
      @reserved_word_array = %w(insert remove edit error correction instantiate move undo)
      super xml_node
    end

    #a special register function is used by the History, instead of the usual add child to avoid adding a history of the history to the history
    def register change, owner
      current_change = change
      while current_change do
        current_change[:owner] = owner
        #adding to head so latest changes are on top
        @xml_cursor.children.first.add_previous_sibling
        @children.add_child current_change
        current_change.next!
      end
    end

    def generate_descr

    end

    def register_with_owner change
      d "@parent: #{@parent.inspect}"
      register change, @parent[:owner]
    end

    def size
      @children.size
    end

    def change_hash
      @children_hash
    end

    def get_changes
      #handle cases for searches by: date, date range, owner, type, target,
    end

    private :register
  end

  #individual change; not to be used, only for subclassing
  class Change < Component
    def initialize xml_node, args = {}
      super xml_node
    end

    def generate_new_xml args
      super
      @previous = args[:previous]
      @next = nil
      @xml_cursor['previous'] = @previous.id
      @ref = args[:ref]
      @xml_cursor['ref'] = @ref.id
      @timestamp = Time.now
      @xml_cursor.element 'date', @timestamp.to_s
      #description will be generated or input later and only when triggered
      @xml_cursor.element 'description'
    end

    def generate_descr
      @description = " at #{@timestamp}."
    end

    def << component
      if component.is_a? Change
        @next = component
        component.previous = self
        component
      else
        super component
      end
    end

    def previous= ref
      @previous ||= ref
    end

    private :generate_descr

    attr_reader :next, :ref, :timestamp, :description
  end

  #Component instantiated; holds pointers to Edits to parameter values if redefined for this instance
  #holds pointer to antecedent; generates fresh ID for instance; adds as new child to template
  class Instantiate < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  #error found during build inspection process (syntax errors) or during general inspection - saved to file if uncorrected on commit
  #points to rule violated and/or syntax marker and previous error in exception stack
  class Error < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  #build-time, inspection or committed error correction - points to error object
  #also points to change object that precipitated this one
  #(could be another correction or other change-type other than Error or Instantiate)
  class Correction < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  #removal of node can occur when building design from de-instantiation (@if == false)
  #when inspecting from a given perspective, or from user input when editing
  class Remove < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  #insertion of node can occur when building design from instantiation
  #after inspector reports changes (when historian inserts changes into history)
  #and from user input when editing
  #the initialization strings really should be loaded from the RelaxNG. LATER!!!
  class Insert < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    #because owner is not known until insert is registered with history, this method is kept private
    def generate_descr
      self[:description] = "#{self[:owner].to_s} added #{@ref.root_name} (#{@ref.id}) to #{@ref.parent.root_name} (#{@ref.id})" + self[:description]
    end

    private :generate_descr
  end

  class Move < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
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


    def initialize xml_node, args = {}
      super xml_node, args
    end


    def generate_new_xml
    end
  end

  class Undo < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  #instances are copies (dclones) or aliases (clones) of a given Component; if copies, they get Instances of the children also
  #when used to wrap a Component or set of Components, allows use of locally-namespaced parameters
  #when empty but given a target Component, creates copy and added as new child or creates alias and added as mirror child
  #wrapper is removed after build; aliases
  class Instance < Component
    #instances can expect reserved component element names AND parameter assignment hash
    def initialize xml_node, args = {}
      @reserved_word_array = %w(parameters array instance)
      super xml_node
    end

    def get_params
      parameters = find_child'parameters'
      if parameters
        parameters
      else
        {}
      end
    end

    def get_param_val arg
      get_param_hash[arg].value
    end
  end

  #links function as aliases of a given Component; essentially they are the same object but in target location and location of Link object
  #actually implemented by redirecting pointers to target; Link Components must never have children!! any children added will be added to target!!
  class Link < Component
    def initialize xml_node, args = {}
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
    def initialize xml_node, args = {}
      super xml_node
    end
  end

  #basic means of creating patterned clones of a component; can contain a design or instances
  class Array < Instance
    def initialize xml_node, args = {}
      super xml_node
    end

    def size
      get_attr_val 'size'
    end
  end

  #container for multiple parameters
  class Parameters < Component
    @reserved_word_array = 'parameter'
    def initialize xml_node, args = {}
      super xml_node
    end

    def update params
      last_change = nil
      @children_hash.merge params.children_hash do |key, old_val, new_val|
         @children_hash[key] = new_val
        last_change << (catch :edit)
      end
      collect_changes last_change
    end
  end

  #specialization of Component holds parameter name, value and description
  #also, during Build, its abstracts and concretes track parameter value overrides
  class Parameter < Component
    def initialize xml_node, args = {}
      super xml_node
    end

    def value
      self['value']
    end

    #parameter value assignments must be recorded
    def value= val
      if val != self[:value]
        value = val
        throw :edit, Edit.new(nil, self)
      end
    end
  end
end
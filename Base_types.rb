# the component is the base of every object in DesignOS and any designs produced in it.
# components consist of components and never overlap. therefore a general tree structure is perfect
# for representing component structures and also works perfectly with XML
# however, DesignOS needs to be able to traverse concreteward and abstractward
# and there are up to as many of each as there are views; change timestamps are a view (concrete if after a change, abstract if before);
# for example: when a parameter is set, the resulting design is a concrete child
# if that parameter value is overridden by a subtemplate, that produces a concrete grandchild
# therefore, every node in this new type of tree is also a member of a hash of arrays - one hash for each query, and
# view hashes are only constructed upon query except for those needed by DesignOS to perform
#
# changes made to Components are made to both the XML node and data node simultaneously
# in order to provide real-time feedback to XML editor
# could add switch to turn this off
module Base_types
  # authentication gem
  # require 'devise'
  # XML parsing and manipulation
  require 'rubytree'
  require 'nokogiri'
  include Tree
  # Components are equivalent to objects in OOP; they are implemented as XML structures that have no branching except for the Component's children.
  # in addition they are Kansei objects existing along two concrete/abstract dimensions, one for views, the other for builds
  # each Kansei object is also a Tree::TreeNode
  # disabling kansei features until we can architect it properly

  class Component < Tree::TreeNode
    # pull out some of these attributes and make them subclasses - like static vs dynamic members?
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
    # shortcut
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
          content << "'#{child.root_name}' "
        end
      else
        content = "content: #{self.content}"
      end
      puts "Component '#{root_name}' #{content}"
    end

    # creating new Component from XML node (from file) or input in the form of XML string
    def initialize xml_node, args = {}
      unless xml_node.is_a? Nokogiri::XML::Element
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
      super(self.object_id.to_s, @xml_root_node)
      # traverse and load Component from xml
      collect_changes traverse_xml load_methods %w(load_attributes init_reserved chase_tail init_generic)
    end

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

    def do_nothing arg = nil
      # this is silly
    end

    def generate_new_xml args = {}
      element_name = self.class.to_s.downcase!
      element_name[/.*(?:(::))/] = ''
      @xml_root_node = @xml_cursor = element(element_name(args[:content]))
    end

    def generate_descr

    end

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
      child_class = Object::const_get("Base_types::#{child.name.capitalize}")
      self << child_class.new(child)
    end

    # child is just XML - wrap it
    def init_generic child
      self << Component.new(child)
    end

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
            @attributes[attr.name.to_sym] = attr
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
      if attr.is_a? Nokogiri::XML::Attr
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

    def find_child child
      @children.each do |cur_child|
        return cur_child if cur_child.root_name == child
      end
      @children[child]
    rescue TypeError
      @children_hash[child]
    end

    # a slightly safer way to get an attribute's final value (read only)
    def get_attr_val attr
      @attributes[attr].value
    end

    # redefining TreeNode::name as Component::id
    alias_method :id, :name

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

    def element name, content = nil
      doc = @xml_doc || @xml_root_node.document
      new_element = Nokogiri::XML::Element.new name, doc
      if content
        new_element.content = content
      end
      new_element
    end


    private :element, :load_attributes, :init_reserved, :init_generic, :chase_tail, :traverse_xml, :find_parameterized_nodes, :add_if_parameterized, :reconcile, :generate_new_xml, :load_content_if_leaf, :collect_changes, :load_methods
  end

  # template Owners class - contains Owner Hash
  class Owners < Component
    def initialize xml_node
      @reserved_word_array = 'owner'
      super xml_node
    end
  end

  # template Owner class
  class Owner < Component
    def initialize xml_node, args ={}
      super xml_node
    end

    def generate_new_xml args
      @xml_cursor
    end
  end

  # Templates are components that constitute a distinct technology
  # They must have owners and always record sub-component changes
  # Element names reserved by the template's schema rules become constructors for sub-components
  class Template < Component
    # points to actual xml document. @xml_root_node points to the root element.
    @xml_doc
    # users or processes that created this template
    @owners

    def initialize template_root_node, args = {}
      @reserved_word_array = %w(owners history design)
      # creating new template
      super template_root_node, args
    end

    def history
      find_child 'history'
    end

    def design
      find_child 'design'
    end

    def owners
      find_child 'owners'
    end

    def generate_new_xml args = {}
      @xml_doc = Nokogiri::XML::Document.new
      super
      @xml_doc << @xml_cursor
      @xml_root_node['visible'] = args[:owner].object_id.to_s
    end
  end

  # all templates have histories and objects that have been queried
  # might need to wrap in module to namespace?
  class History < Component
    def initialize xml_node
      @reserved_word_array = %w(insert remove edit error correction instantiate move undo)
      super xml_node
    end

    # a special register function is used by the History, instead of the usual add child to avoid adding a history of the history to the history
    def register change, owner
      current_change = change
      while current_change do
        current_change[:owner] = owner
        # adding to head so latest changes are on top
        @xml_cursor.children.first.add_previous_sibling
        @children.add_child current_change
        current_change.next!
      end
    end

    def generate_descr

    end

    def register_with_owner change
      register change, @parent.owners
    end

    def size
      @children.size
    end

    def change_hash
      @children_hash
    end

    def get_changes
      # handle cases for searches by: date, date range, owner, type, target,
    end

    private :register
  end

  # individual change; not to be used, only for subclassing
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
      # description will be generated or input later and only when triggered
      @xml_cursor.element 'description'
    end

    def generate_descr
      @description = " at #{@timestamp}."
    end

    def push component
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

  # Component instantiated; holds pointers to Edits to parameter values if redefined for this instance
  # holds pointer to antecedent; generates fresh ID for instance; adds as new child to template
  class Instantiate < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  # error found during build inspection process (syntax errors) or during general inspection - saved to file if uncorrected on commit
  # points to rule violated and/or syntax marker and previous error in exception stack
  class Error < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  # build-time, inspection or committed error correction - points to error object
  # also points to change object that precipitated this one
  # (could be another correction or other change-type other than Error or Instantiate)
  class Correction < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  # removal of node can occur when building design from de-instantiation (@if == false)
  # when inspecting from a given perspective, or from user input when editing
  class Remove < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  # insertion of node can occur when building design from instantiation
  # after inspector reports changes (when historian inserts changes into history)
  # and from user input when editing
  # the initialization strings really should be loaded from the RelaxNG. LATER!!!
  class Insert < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    # because owner is not known until insert is registered with history, this method is kept private
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

  # change to element content or attribute value, essentially the actual content of the Component has changed
  # this can occur from owner input when editing
  # or initiated by Builder when dealing with parameters (and nothing else)
  class Edit < Change
    # string containing new content
    @new_content
    # string containing old content (if content is XML, string can be converted to XML)
    @old_content
    # xpath to changed element
    @xpath
    # string if empty content change was to element; if non-empty is name of attribute value changed
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

  # instances are copies (dclones) or aliases (clones) of a given Component; if copies, they get Instances of the children also
  # when used to wrap a Component or set of Components, allows use of locally-namespaced parameters
  # when empty but given a target Component, creates copy and added as new child or creates alias and added as mirror child
  # wrapper is removed after build; aliases
  class Instance < Component
    # instances can expect reserved component element names AND parameter assignment hash
    def initialize xml_node, args = {}
      @reserved_word_array = %w(parameters array instance)
      super xml_node
    end

    def params
      parameters = find_child'parameters'
      if parameters
        parameters
      end
    end

    def param_val arg
      get_param_hash[arg].value
    end
  end

  # links function as aliases of a given Component; essentially they are the same object but in target location and location of Link object
  # actually implemented by redirecting pointers to target; Link Components must never have children!! any children added will be added to target!!
  class Link < Component
    def initialize xml_node, args = {}
      @reserved_word_array = []
      super xml_node
    end

    # is link live? links can be broken if the target object is removed after the link is created
    def link?
      true
    end
  end

  # part of the template file that actually contains the design or content
  # specifies logics allowed within itself
  class Design < Instance
    @logic
    attr_accessor :logic

    def initialize xml_node, args = {}
      super xml_node
      # defining default logics here for now (make constant later? or builder template property?)
      if get_attr_val(:logics).nil?
        @attributes[:logics].value = %w(logic)
      end

      # also hardcoding relative path of logic template file for now
      # will need to load from registry later
      get_attr_val(logics).each do |logic|
        @logic = Logic.new(logic)
      end
    end
  end

  # basic means of creating patterned clones of a component; can contain a design or instances
  class Array < Instance
    def initialize xml_node, args = {}
      super xml_node
    end

    def size
      get_attr_val :size
    end
  end

  # container for multiple parameters
  # NOT DONE YET - how to load values into Dentaku memory?
  class Parameters < Component
    @reserved_word_array = 'parameter'
    def initialize xml_node, args = {}
      super xml_node
    end

    def parameter_hash
      @children_hash
    end

    def update params
      if params
        last_change = nil
        @children_hash.merge params.parameter_hash do |key, old_val, new_val|
           @children_hash[key] = new_val
          last_change.push (catch :edit)
        end
        collect_changes last_change
      end
    end
  end

  # specialization of Component holds parameter name, value and description
  # also, during Build, its abstracts and concretes track parameter value overrides
  class Parameter < Component
    def initialize xml_node, args = {}
      super xml_node
    end

    def value
      self['value']
    end

    # parameter value assignments must be recorded
    def value= val
      if val != self[:value]
        value = val
        throw :edit, Edit.new(nil, self)
      end
    end
  end

  class Logic < Component
    # later this should load like a regular template (probably as part of inspector?)
    # then it will be a run time that listens for operations and reports performance
    def initialize logic_file_name
      file = File.open "#{logic_file_name}.xml"
      xml_doc = Nokogiri::XML file
      super xml_doc.root
    end

    # returns operator or operators that match arg; returns all if no arg
    def [] *args
      ops = []
      args.each do |arg|
        children.each do |operator|
          ops << operator.key(arg)
        end
        ops.size > 1 ? ops : ops[0]
      end
      args ? ops : children
    end

    # returns array of operator names starting in priority from the given symbol and working down if none found
    # in other words, this method will always return an array with an index for each operator,
    # the key is the pattern that constrains which operators' names are to be returned e.g. by type, inverse, etc.
    def names sym, key=nil
      a = []
      if key ary = self[key]
        else ary = self[]
      end
      aryeach do |operator|
        case sym
          when :regexp then a << (operator.regexp ? operator.regexp : operator.symbol)
          when :symbol then a << operator.symbol
          when :name then a << operator.names[sym][0]
          else a << operator.names[sym]
        end
      end
      a
    end

      private

    # logics required for this logic to work i.e. definitions of these operations use operators defined in another logic
    def dependencies
      find_child('dependencies')
    end
  end

  # container for every possible property of an operator
  class Operator < Component
    # any of the following can be used as a key to retrieve this operator
    # symbol that most commonly represents operator e.g. +,-
    @symbol
    # regexp used to find this operator in standard parameterized string
    @regexp
    # alternate name hash; keys are domains in which names are used
    @names
    # actual method to call when operator invoked
    @proc

    attr_reader :symbol, :names

    def initialize args={}
      super args

      # this name is guaranteed to be safe in any context (C-identifier string)
      @names[:safe] = id
      find_child('names').each do |name|
        case name.element.to_sym
          when :symbol then @symbol = name
          when :regexp then @regexp = name
          when :name
            @names[:name].is_a?(Array) ? (@names[:name] << name) : (@names[:name] = [name])
          else @names[name.element.to_sym] = name
        end
      end
    end

    # looks up arg and returns this operator if match found
    def key arg
      [@symbol+@names+@proc+@attributes[:type].value].each do |obj|
        return self if obj == arg || obj.to_s == arg
      end
    end

    # number of arguments
    def arity
      @attributes[:arity] || 2
    end

    # logics that include this operator; default is system's logic
    def logics
      @attributes[:logics] || :system
    end

    # is operator bound to term on its right? e.g. -x, !x
    def right_associative?
      @attributes[:right_associate]
    end

    # constant 'I' that for this operator 'op' meets definition: x op I == x; not all operators have identities
    def identity
      @attributes[:identity]
    end

    # only applies to inequalities; flips direction of operator when expression is negated
    def reverse
      @attributes[:reverse] || self
    end

    # operation that cancels out this operation; some operations' inverses may not be members of the same logics
    # will return nil if no inverse available
    def inverse
      @attributes[:inverse]
    end

    # order of operations (higher integer is first)
    def precedence
      @attributes[:precedence] || 0
    end
  end
end
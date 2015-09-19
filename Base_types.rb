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
    @id
    @xml_root_node = Nokogiri::XML::Element
    @views = []
    @builds = {}
    @reserved_word_array = []
    @attributes = {}
    @xml_cursor
    @visible = []
    @if = ''
    @parameterized_nodes = {}

    def xml
      @xml_root_node
    end

    def to_s
      puts "root element: #{element}; children:"
      i = 0
      @children.each do |child|
        puts "#{i}: #{child.content.name}"
        i += 1
      end
    end

    def initialize xml_root_node, args = {}
      #STDERR.puts "#{__LINE__}: '#{xml_root_node.name}' initializing"
      @xml_cursor = @xml_root_node = xml_root_node
      @if = []
      @visible = ['admin']
      @parameterized_nodes = Hash.new
      @attributes = Hash.new
      @views = Hash.new
      @builds = Hash.new
      @reserved_word_array = args[:reserved] || []
      super(self.object_id.to_s, @xml_root_node)

      loading_methods = {born: lambda{load_attributes}, child: lambda{load_child}}
      traverse_xml @xml_cursor, loading_methods

      @id ||= self.object_id.to_s
      @xml_cursor = @xml_root_node
    end

    #recurses from a given xml element; give it various tasks using method hash
    def traverse_xml xml_cursor, method_hash
      @xml_cursor = xml_cursor
      method_hash[:born].call
      return if xml_cursor.element_children.size == 0
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
            if attr.name == 'id'
              @id = attr.value
            else
              @id = @id || attr.value
            end
          when 'visible'
            @visible << " #{attr.value}"
          when 'if'
            @if << attr
          else
            @attributes[attr.name] = attr
        end
      end
    end

    def get_parameterized_xml_nodes
      @parameterized_nodes = nil
      resolve_methods = {born: lambda{find_parameterized_nodes}, child: lambda{@xml_cursor = nil}}
      traverse_xml @xml_root_node, resolve_methods
      @parameterized_nodes
    end

    def find_parameterized_nodes
      @if.each do |condition_node|
        add_if_parameterized condition_node
      end
      @attributes.each do |attr|
        add_if_parameterized attr
      end
    end

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

    #element name for the root of this Component

    @root_xml_node = Nokogiri::XML::Element

    #description of what this component represents in a design; can contain XML e.g. DITA content
    #at its most basic it is the comment on the subclass of Component or annotation in the schema rules
    @@description


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

    attr_reader :id, :builds, :views, :children, :children_hash, :parameterized_nodes

    private :load_attributes, :traverse_xml, :load_child, :find_parameterized_nodes, :add_if_parameterized, :reconcile
  end

  #template Owners class - contains Owner Hash
  class Owners < Component
    attr_reader :owner_hash

    def initialize xml_node, args = {}
      super xml_node, args
      @owner_hash = Hash.new
      @children.each do |owner|
        @owner_hash[owner.xml_node['id']] = owner
      end
    end
  end

  #template Owner class
  class Owner < Component
    #owner's full name
    @full_name
    attr_reader :full_name
    def initialize xml_node, args = {}
      super xml_node, args
      #pulling owner's full name from file
      @full_name = @children_hash['name']
    end
  end

  #Templates are components that constitute a distinct technology
  #They must have owners and always record sub-component changes
  #Element names reserved by the template's schema rules become constructors for sub-components
  class Template < Component
    #or pass an argument to sub template
    def initialize template_root_node, args
      super template_root_node
    end

    alias_method :get, :find_child

    def get_name
      find_child('name').content
    end

    def get_version
      find_child('version').content
    end
  end


  #all templates have histories and objects that have been queried
  class History < Component

    def initialize xml_node, args={}
      STDERR.puts "#{__LINE__} initialize History with xml_node.name=#{xml_node.name} using args=#{args.inspect}"
      super xml_node
      #stuff goes here
    end

    def size
      @children.size
    end

    def history_hash
      @children_hash
    end
  end

  #individual change; not to be used, only for subclassing
  class Change < Component
    @object_ref
    @timestamp
    @owner

    def initialize xml_node
    end
  end

  #Component instantiated; holds pointers to Edits to parameter values if redefined for this instance
  #holds pointer to antecedent; generates fresh ID for instance; adds as new child to template
  class Instantiate < Change

  end

  #error found during build inspection process (syntax errors) or during general inspection - saved to file if uncorrected on commit
  #points to rule violated and/or syntax marker and previous error in exception stack
  class Error < Change

  end

  #build-time, inspection or committed error correction - points to error object
  #also points to change object that precipitated this one
  #(could be another correction or other change-type other than Error or Instantiate)
  class Correction < Change
    #object ref is to a rule
  end

  #removal of node can occur when building design from de-instantiation (@if == false)
  #when inspecting from a given perspective, or from user input when editing
  class Remove < Change
    #root change of removed tree; may be same as this change
    @original_change
    #children that were removed with this object
    @old_children
    #previous change according to @timestamp
    @previous
  end

  #insertion of node can occur when building design from instantiation
  #after inspector reports changes (when historian inserts changes into history)
  #and from user input when editing
  class Insert < Change
    @original_change
    #children of this object added with this change
    @new_children
    #next change according to @timestamp
    @next
  end

  #moves occur during editing from user input and from the Inspector traversing conflicting views
  #for example, in one view, a Component may be in location A, but in another view, it is in location B.
  #this is not, strictly speaking, movement, but if an object appears to change locations when the Inspector is traversing views
  #it will record this as a Move. The following example may help: a group of users all agree that tomatoes are vegetables
  #another group of users is equally adamant that they are fruits. assuming that tomatoes are children of one or the other branch of the produce tree
  #when switching from one group's view to another, tomatoes will appear to have moved from the fruit to the vegetable branches and vice versa
  #a hypothetical 'plants' view will never see this change as it is above that dispute
  class Move < Change
    #parent prior to move
    @old_parent
    #new parent after move
    @new_parent
    @previous
    @next
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
  end

  #changes to changes
  class Reverse < Change
    #if the user supplied a time instead of number of changes removed, it can be compared to this timestamp and those of
    #the new @previous and @next changes. if neither previous or next are equal, then almost certainly the reversion
    #was not specifically targeted at this object but rather another; if none, then the time/date of a design freeze of some kind
    @requested_timestamp = false
    #how many changes back we reverted
    @num_changes_removed
    #the change before this reversion is now a dead piece of the design
    @old_previous
    #the new previous (simply @previous here to be consistent across classes) will now skip over those dead changes
    @previous
    @next

    def initialize(timestamp_or_num_changes)
      if timestamp_or_num_changes < 100
        @num_changes_removed = time_stamp_or_num_changes
      else
        @requested_timestamp = time_stamp_or_num_changes
        @num_changes_removed = asdf
      end
    end
  end

  #template file that holds the keywords each view can see
  #FOOBAR - rewrite this as a contextualized global object - whatever object receives this gets this view's members
  #as opposed to making views a system global created on user login
  class View < Template
    #keywords that make up this view; distinct from this component's own keywords (which should only consist of admin and the owners' ids)
    @view_keywords

    def initialize template_file, args = {}
      #calling standard template initialize
      super template_file, args
      #either way, argument keywords get added
      @view_keywords = args[keywords] + self.children.each.content
    end

    def can_see? keyword
      @view_keywords.include? keyword
    end
  end

  #basic means of creating clones of a component; can have its own parameters so it can be a variant; instances point to Components or Templates
  class Instance < Component
    #reference design's id
    @ref
    #hash of parameter name:component pairs
    @parameter_hash

    attr_accessor :ref, :parameter_hash

    #instances can expect reserved component element names AND parameter assignment hash
    def initialize xml_node, args = {}
      @parameter_hash = args[:parameters]
      STDERR.puts "#{__LINE__} initialize #{self.class.to_s} with xml_node.name=#{xml_node.name} using args=#{args.inspect}"
      super xml_node, args
      #all instances have a reference, but they do not need to be external - some can reference self
      @ref = @xml_node['ref']

      #set parameters pointer
      STDERR.puts "#{__LINE__} Instance has following children: #{@children.inspect}"
      if child('parameters')
        STDERR.puts "#{__LINE__} found parameters!"
        @parameter_hash = child('parameters').parameter_hash
        STDERR.puts "#{__LINE__} loaded @parameter_hash: #{@parameter_hash.inspect}!"
      end
    end
  end

  #part of the template file that actually contains the design or content
  #specifies logics allowed within itself
  class System < Instance
    #key is logic name; value is logic template
    @logic_hash

    attr_reader :logics

    #arguments are parameter name:value pairs from build stack
    def initialize xml_node, args = {}
      STDERR.puts "#{__LINE__} initialize #{self.class.to_s} with xml_node.name=#{xml_node.name} using args=#{args.inspect}"
      #pull in logics
      xml_node.attribute('logics').to_s.split(' ').each do |logic|
        #@logics[logic] = Logic.new logic
      end
      #build up Components
      super xml_node
    end

    #aggregates all operations of all logics of this system and flattens into single hash
    def get_system_ops
      Hash operations
      @logic_hash.values.each do |logic|
        operations.merge! logic.operator_hash
      end
      operations
    end
  end

  #basic means of creating patterned clones of a component; can contain a design or instances
  class Array < Instance
    #represents size of array but can be a parameter
    @size

    attr_accessor :size

    def initialize xml_node, args = {}
      STDERR.puts "#{__LINE__} initialize #{self.class.to_s} with xml_node.name=#{xml_node.name} using args=#{args.inspect}"
      super xml_node
      @size = @xml_node['size']
      #automagically creating parameter of type iterator i.e. the array pattern seed
      @parameters << Parameter.new_iterator
    end
  end

  class Logic < Template
    #hash of operators and the code they execute
    @operator_hash

    attr_reader :operator_hash
    def initialize logic_template
      super logic_template
      #looping through each operator and adding to hash
      @system.children.each do |operator|
        @operator_hash[operator.name] = operator.code
      end
    end
  end

  #create operator from methods loaded from logic template
  class Operator < Component
    #hash key
    @name
    #executable Ruby
    @code

    attr_accessor :name, :code

    def initialize node
      #operator name and id are the same
      @name = node[:id]
      if respond_to? @name
        #operator is already defined in Ruby
        @code = @name
      else
        #pulling in operator definition from template
        @code = node.content
      end
    end
  end

  #container for multiple parameters
  #FUBAR - figure out whether you want to sort out overrides here or in instance!
  class Parameters < Component
    #hash of parameter name:component pairs
    @parameter_hash

    attr_reader :parameter_hash

    #not working yet?
    def initialize xml_node, args = {}
      STDERR.puts "#{__LINE__} initialize #{self.class.to_s} with xml_node.name=#{xml_node.name} using args=#{args.inspect}"
      @parameter_hash = Hash.new
      super xml_node, args
      STDERR.puts "#{__LINE__} #{@children.size.to_s} children found!! @children=#{@children.inspect}" if element == "parameters"
      #loading override params hash; key is parameter name
      overriding_parameters = args['parameters']
      #looping through all parameter children
      @children.each do |parameter|
        STDERR.puts "#{__LINE__} working parameter=#{parameter.inspect}"
        #searches for parameter name match
        overriding_param = overriding_parameters[parameter.name]
        #if overriding param found - override
        if overriding_param
          parameter.override overriding_param
        end
        #add parameter including overrides to hash
        @parameter_hash[parameter[name]] = parameter
      end
    end
  end

  #specialization of Component holds parameter name, value and description
  #also, during Build, its abstracts and concretes track parameter value overrides
  class Parameter < Component
    #name of the parameter - outward facing; id tracks inward facing name
    @name
    #value at this moment of instantiation
    @value
    #at least one level (preferably highest) usage of parameter should have description
    #if more, they can be concatenated?
    @description
    #scope of this parameter: can be written from above, read from below or local
    @scope
    #type - integer, float, string, Boolean -
    #in accordance with Ruby principles, these types are not strict,
    #but for XML purposes and for parameter overrides type must remain constant i.e. you can't override an integer with a string
    #if you need to convert the value, do it outside this class by calling .value and using conversion method on it
    #unresolved parameters are strings
    @type

    attr_reader :name, :value, :description, :type

    def initialize xml_node, new_value=nil
      STDERR.puts "#{__LINE__} initialize #{self.class.to_s} with xml_node.name=#{xml_node.name} using args=#{new_value.inspect}"
      #standard Component initializer
      super xml_node, nil
      if new_value
        #assigning given value
        @value = new_value
      else
        #if none given pulling one from given XML (default behavior)
        @value = @root_xml_node['value']
      end
      @name = @root_xml_node['name']
      @description = @root_xml_node.child('description').content
      @scope = @root_xml_node['scope']
      @type = @value.class
    end

    #creates a special parameter called an iterator that can only be an integer with scope local to an Array
    def self.new_iterator
      @name = 'iterator'
      @value = 0
      @description = 'Auto-generated iterator parameter for this array.'
      set_id
      @keywords += 'iterator'
      #local scope means inspector will not track changes to its value
      @scope = 'local'
    end

    #assigns value to parameter
    def override parameter=nil
      if parameter
        #creating abstract - if variation of this parameter is without a value
        add_abstract 'parameter', self
        #override value
        @value = parameter.value
        #append description; string operation for now. may need to make array?
        @description += "\n#{parameter.description}"
      else
        #null value assigned; design has become more abstract - make self its own concrete child
        #string is name of associated view, in this case visible to the build process
        add_concrete 'parameter', self
        #override value
        @value = nil
      end
    end
  end

  #template file that holds list of DesignOS users and their views
  class Registry < Template
    #use regular template init
    def initialize registry_file
      super registry_file
    end

    #user id must be provided by user for now; could pull from environment
    #args are for if new user is being created by an admin and is being given starting views and owned templates
    def new_user user_id, *args
      @registry << User.new(user_id, args)
    end

    #private - looks up given user id
    def find_user user_id
      @registry.child('users').children.each do |user|
        user if user.name == user_id
      end
    end
  end

  #a User can be either an owner (allowed to write) or not (only allowed to see content that passes authorized view filters)
  class User < Component
    #hash of views available to this user
    @views
    #hash of owned templates
    @ownership_list
    #string of user's id; equivalent to Tree::Node.name
    alias_method :user_id, :name
    #user's full name
    @full_name\

    #creating new user
    def initialize user_id, *args
      @full_name = args[name]
      @views = args[keywords]
      @user_id = user_id
    end

    def get_names
      return @user_id, @full_name
    end

    attr_reader :views, :full_name, :ownership_list, :user_id

    #traces ownership of given template to see if this user can contribute
    def owns template
      #if this template is on this User's list then yes, they own this template
      if @ownership_list.include? template
        true
      end
      #if this template has this user on the list of owners
      #then this user's ownership list needs to be updated; and yes, they own this template
      if template.owners.include? self
        @ownership_list<<template
        true
      end
      #if neither the template or the user names the other, then no, it's not my template
      #could also add code for user to request owners for membership
      false
    end
  end
end
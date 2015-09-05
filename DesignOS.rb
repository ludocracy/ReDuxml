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
  #basic tree structure, providing attributes: @name, @children, @siblings, @parent, @content etc.
  require 'rubytree'
  #XML parsing and manipulation
  require 'nokogiri'

  #had to create my own close parentheses finder
  def find_close_parens_index string
    #tracks current index of string
    pos = 0
    #tracks how many parentheses deep we're nested
    parens_depth = 0
    #looping through each char
    string.each do |char|
      case char
        #found a close parenthesis
        when ')'
          #move down a level
          parens_depth -= 1
          throw :close
        #found an open parenthesis
        when '('
          #move up a level
          parens_depth += 1
          throw :iterate
        else
          throw :iterate
      end

      #do this whenever close parenthesis found
      catch :close do
        case parens_depth
          #depth is 0 - we found it!
          when 0
            #return current char index
            return pos
          #how'd we go negative?
          when parens_depth < 0
            #throw an error - this needs to generate an error if user does not correct!
            throw :too_many_close_parens, 'parentheses error! too many close parentheses!'
          else
        end
      end

      #increment position index
      catch :iterate do
        pos += 1
      end
    end #end of string loop

    #method should not get here unless it never found enough close parentheses
    throw :too_many_open_parens, 'parentheses error! too many open parentheses!'
  end

  private :find_close_parens_index

  #Design elements are XML Element Nodes but with the addition of DesignOS attributes
  class Design_element < Nokogiri::XML::Element
    #searches attribute values and element content for parameter expressions and returns them as array of strings
    def get_macro_strings
      #adding element content to total string to look for expressions
      content_string = self.content
      #looping through attribute values to find its parameter expressions
      self.attributes.each.values do |value_string|
        #adding to total string
        content_string << value_string
      end

      #creating array to hold any discovered macro strings
      parameter_macro_strings = []
      #passing total string to current string
      content_string_stub = content_string
      #looping through total string, looking for macro string wrapper around parameter expression
      loop do
        #looks for macro string start index or returns -1 if not found
        macro_string_index = self.content.find_index'@(' || -1
        #we'll make the current string the start of this macro string
        content_string_stub = self.content[macro_string_index]
        #if passed -1, the resulting stub should be too short to contain any macro strings
        #or passed an empty parameter expression no processing needed
        if content_string_stub.size > 3
          #find the end of the macro string
          macro_string_close_index = find_close_parens_index content_string_stub
          #add macro string to array
          parameter_macro_strings << content_string_stub[0...macro_string_close_index]
          content_string_stub = content_string_stub[macro_string_close_index]
        else
          return nil
        end
      end
      parameter_macro_strings
    end

    #replace macro strings in attributes and element content with provided values
    def resolve_element macro_value_hash
      #loop through each provided macro_string/value pair
      macro_value_hash.each do |macro_value_pair|
        #replacing macro strings in element content
        self.content = replace_macro_strings self.content, macro_value_pair
        #looping through each attribute of this element
        self.attributes.each do |attr|
          attr.value = replace_macro_strings attr.value, macro_value_pair
        end
      end
    end

    #replaces macro strings  with given values
    def replace_macro_strings string, macro_value_hash
      string[macro_value_hash.key] = macro_value_hash.value
    end

    private :replace_macro_strings
  end


  #Components are Tree nodes where each tree node is a hash of abstract and concrete versions of the Component
  #They are equivalent to objects in OOP; they are implemented as XML structures that have no branching except for the Component's children.
  class Component < Tree::TreeNode

    #redefining TreeNode::name as Component::id
    alias_method :id, :name

    #element name for the root of this Component
    @root

    #TreeNode.content will serve many purposes
    #depending on the Component type it could be the description, full name, or other documentation content
    #some may be namespaced to allow DITA or other docs XML formats

    #concrete object descendants - Hash of Hash of variations of this Component that are more concrete (more specified) than this one
    #outer Hash keys are views, inner Hash keys are names (root elements) of Components; values are Components
    @concretes

    #abstract ancestors - Hash of Hash of variations of this Component that are more abstract (less specified) than this one
    #outer Hash keys are views, inner Hash keys are names (root elements) of Components; values are Components
    @abstracts

    #keyword-sets (views) of this object -  at least one must be true for this Object to be viewable by user
    @keywords

    #points to root element of corresponding XML object
    @node_xpath

    #rules that govern this Component's visibility or existence; keys are xml_node; value is if statement
    @rule_hash

    #these attributes can be read and written freely so that the user can modify the design
    #might need to wrap in proper methods to prevent modification of reserved views and rules
    attr_accessor :rules
    #these attributes require specific methods to write to
    #the node's xpath is determined by its position in the tree, plus intermediate XML elements
    #the concrete and abstract instances can only be removed by the Inspector (when memory/performance constraints are exceeded)
    attr_reader :node_xpath, :concretes, :abstracts, :id, :root

    #setting id in data object and XML
    def set_id
      @id = @node_xpath['id']
      #if XML has no id, give it one from Component's global id
      if @id == ''
        @id = @node_xpath['id'] = self.object_id
      end
    end

    #adds new concrete child with its name as key to Hash with the key 'view'
    def add_concrete view, name_component_pair
      @concretes[view] << name_component_pair
    end

    #adds new abstract child with its name as key to Hash with the key 'view'
    def add_abstract view, name_component_pair
      @abstracts[view] << name_component_pair
    end

    #can a given view see this component?
    def seen_by *views
      views.each do |view|
        if view.can_see @keywords
          true
        end
      end
      false
    end

    #scrubs keywords of ones that should not be inherited by new children components
    def scrub_reserved key_words
      #list includes: singleton (because child may not be one), element name because child element will surely differ
      key_words.include [:singleton]
    end
    private :scrub_reserved, :set_id

    #the builder should provide the XML node to be converted to rubytree node
    #also what keywords does this component inherit?
    def initialize xml_node, args
      #only XML nodes (Nokogiri in this case) allowed
      raise 'Attempted to initialize Component with object other than XML node' unless xml_node.is_a? Nokogiri::XML::Node
      @root = xml_node.name
      #adding inherited key_words
      @keywords = args['key_words'].to_a
      #storing node's XML XPATH
      @node_xpath = xml_node
      @rule_hash = Hash.new
      #setting or getting id -- all Components must have a unique global id
      set_id
      #looping through children; repurposing xml_node to be current_xml_node
      while xml_node
        #picking up design conditionals as rules
        @rule_hash[xml_node] = xml_node['if']
        #and picking up view conditions as keywords; adding them to ones inherited
        @keywords << xml_node['keywords'].to_s.split(' ')
        case xml_node.children.size
          #this is a leaf node
          when 0
          when 1
            #if it has no siblings, it's a singleton
            if xml_node.child.siblings.size == 0
              #add to concrete pointer; create new child based on child's class; indicate it is a singleton
              #the view is 'xml', an implicit view that includes XML elements that are not properly a part of the data model
              #in non-XML view (default), traverses will skip these and go straight to children
              name_component_pair = xml_node.child.name <= self.class.new(xml_node.child, @keywords+'singleton')
              add_concrete 'xml', name_component_pair
            end
            #traverse
            xml_node = xml_node.child
          else
            #adding each child
            xml_node.children.each do |child|
              #is this XML element name reserved? if so, call subclass constructor (may need to add namespace of template somehow?)
              if args[:reserved].include? child.name
                #getting class of child
                child_class = Object.const_set(child.name.classify, Class.new)
                #calling that class's initializer - should be subclass of Component
                new_child = {:keywords => scrub_reserved(@keywords)}
                @children << child_class.new(child, new_child)
              end
            end
        end
      end
    end

    #shortcut method
    def template?
      @keywords.include? 'template'
    end

    #shortcut to name, pulled from XML element name
    def name
      @root
    end

    #only use if you know component only has one child with that element name
    def child name
      @children.each do |child_node|
        return child_node if child_node.name == name
      end
      raise "Child \"#{name}\" not found!"
    end
  end

  #template Owners class - contains Owner Hash
  class Owners < Component
    @owner_hash

    attr_reader :owner_hash

    def initialize xml_node, *args
      super xml_node, args
      @children.each do |owner|
        @owner_hash[owner[id]] = owner.owner_name
      end
    end
  end

  #template Owner class
  class Owner < Component
    #owner's full name
    @owner
    attr_reader :owner_name
    def initialize xml_node, *args
      super xml_node, args
      #pulling owner's full name from file
      @owner = @concretes['xml']['name']
    end
  end

  #Templates are components that constitute a distinct technology
  #They must have owners and always record sub-component changes
  #Element names reserved by the template's schema rules become constructors for sub-components
  class Template < Component
    #formal/full name of the template - intended to be outward e.g. customer facing unlike the id (which corresponds to Ruby object ids)
    String @name
    #history Component of given template
    @history
    #Hash of id string : full_name string pairs
    @owners
    #root component of template design
    @system
    #template's must always correspond to a document Node
    alias_method :doc, :node_xpath
    #file object
    @file
    #list of element names reserved by the template (pulled from schema rules)
    #used to call element-specific Component constructors
    @reserved_components

    #following methods are private
    #add or create XML document and set up owners
    def set_doc
      if File.exist? @file
        @doc = Nokogiri::XML @file
      else
        @doc = Nokogiri::XML::Document.new @file
      end
    end

    #sets name - not absolutely required but within DesignOS, user will always be prompted for name
    #filenames do not matter to DesignOS except as an inconvenient form of pointer to resources
    #so name does not have to be same as file name, but beware manual file management if they do not at least match a little
    def set_name name=nil
      if name
        #name provided
        @name = name
      else
        #pull name from file
        @name = self.child('name').content
      end
    end

    #these will be made into class names to call the appropriate Component's initializer
    #'system' is only the default reserved word for the content portion of a Template
    #should be overridden for subclasses of Template
    def self.get_reserved_components
      ['system']
    end

    private :set_doc, :set_name
    attr_reader :doc, :name, :owners
    attr_accessor :system

    #args is a Hash of values to seed a new template file when starting from scratch
    #or pass an argument to sub template
    def initialize template_file, *args
      #these reserved elements are there for all templates
      @reserved_components = [:owners, :history]
      #first item is always done first
      @file = File.new template_file[0]

      #set or create this XML document
      #also finds or creates owners
      set_doc

      #adding class-specific reserved components to the basic ones
      @reserved_components += self.class.get_reserved_components

      #call Component initialize
      @system = super @doc, {reserved: @reserved_components}

      #setting history pointer
      @history = self.child('history')
      #getting owner Hash
      @owners = self.child('owners').owner_hash

      #assigning or getting template formal/full name
      set_name args[name]

      #loading any template arguments as concrete children

      @system.add_concrete args [:user], args[:templates]
    end

    #public method to see if a given template is owned by the user - only way to get write access
    def owner? user_id
      @owners.keys.include? user_id
    end
  end

  #all templates have histories and objects that have been queried
  class History < Component
    #array of changes
    @changes = Hash.new
    #associated object or template
    @referent

    def initialize component
      @referent = component
      if @referent.is_template?
        component.getHistory
      end

    end
  end

  #individual change (detected on file save)
  class Change < Component
    @object_ref
    @timestamp
    @owner

    def initialize()
    end
  end

  #Component instantiated
  class Instantiate < Change

  end

  #error found
  class Error < Change

  end

  #error corrected
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

    #these will be made into class names to call the appropriate Component's initializer
    def self.get_reserved_components
      ['keywords']
    end

    def initialize template_file, *args
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
    @parameters

    attr_accessor :ref, :parameters

    def initialize instance_node, *args
      super instance_node, args
      #all instances have a reference, but they do not need to be external - some can reference self
      @ref = @node_xpath['ref']

      #set parameters pointer
      @parameters = self.child('parameters').parameter_hash
    end
  end

  #part of the template file that actually contains the design or content
  #specifies logics allowed within itself
  class System < Instance
    #key is logic name; value is logic template
    @logic_hash

    attr_reader :logics

    #arguments are parameter name:value pairs from build stack
    def initialize system_node, *args
      #pull in logics
      system_node.attribute('logics').to_s.split(' ').each do |logic|
        @logics[logic] = Logic.new logic
      end
      #build up Components
      super system_node
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

    def initialize array_node, *args
      super array_node
      @size = @node_xpath['size']
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
  class Parameters < Component
    #hash of parameter name:component pairs
    @parameter_hash

    attr_reader :parameter_hash

    #args['parameters'] is a Hash of parameter objects; inherited from higher template usually
    def initialize xml_node, *args
      super xml_node, args
      #loading override params hash; key is parameter name
      overriding_parameters = args['parameters']
      #looping through all parameter children
      @children.each do |parameter|
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

    def initialize xml_node, value=nil
      #standard Component initializer
      super xml_node, nil
      @name = @node_xpath['name']
      #assigning given value; if none given pulling one from given XML (default behavior)
      @value = value ||= @node_xpath['value']
      @description = @node_xpath.child('description').content
      @scope = @node_xpath['scope']
      @type = @value.class
    end

    #creates a special parameter called an iterator that can only be an integer with scope local to an Array
    def new_iterator
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
    #rename doc
    alias_method :registry, :doc

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
    @full_name
    alias_method :user_node, :node_xpath

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

#Editor contains methods for user to interact with design - is a console in its unextended state; can be extended with graphical overlay or enterprise editing tool
module Editor
  include Base_types
  require 'active_support/core_ext/hash/conversions'
  #
  require 'yaml'
  #makes program options available in standard format
  require 'optparse'

  @exit
  @user
  @editor_template

  #load this editor's methods
  def load_editor editor_template_file
    #load template and load methods
    @editor_template = Template.new editor_template_file

    #redo this?!
    #should only make methods in the template public; all else should be made private so that user cannot call them
    @editor_template.child('methods').children.each do |method|
      @methods[method['name']] = method.node_xpath.content
    end
    #zeroing out current template so user can load one
    @current_template = nil
  end

  #rewrite this!
  #if no current template ask for one; if no owner (default on startup) ask for one
  def edit open_template
    @current_template = open_template
    loop do
      #get user input
      user_input = gets
      #execute editor methods
      #methods we need:
      #one for each change: insert, remove,
    end
  end
end


#Builder contains methods for converting template files into design Components
#also has hooks for owners to create, modify, and otherwise manage templates via include File module
module Builder
  include Base_types

  #holds views user can access this iteration
  @views = [nil]
  #holds builder template; adds overrides or new methods in addition to the ones defined below
  @builder_template
  #current build process
  @build
  #holds parameters and their values at the current iteration
  @parameter_hash
  #operator hash
  @operator_hash

  #loads this builder's basic features from builder template file
  def load_builder builder_template_file
    @builder_template = Template.new builder_template_file
  end

  #basic function of builder - takes a Template and builds it out according it its parameters
  def build open_template
    open_template.
    #each method takes the current tree's system (design) and
    #removes non-viewable elements, resolves parameters, and instantiates children
    instantiate parameterize prune open_template.system
  end

  #makes sure this node can be seen by one of the views; returns nil otherwise
  def prune current_node
    #loop through each view
    @views.each do |view|
      #return the moment we find a view that can see this node
      return view.can_see current_node
    end
  end

  #find parameter definitions and
  def parameterize current_node
    #find parameter assignments and add to hash
    @parameter_hash << current_node.child(:parameter)
    #traversing template tree XML and replacing all
    current_node.node_xpath.traverse do |node|
      #get an array of macro strings and loop through them
      Array macro_strings = node.get_macro_strings.each do |macro_string|
        #looping through each known parameter from hash
        @parameter_hash.keys.each do |key|
          #replace parameters with values in given macro string
          macro_string[key.to_s] = @parameter_hash[key]
        end
      end
      #evaluate macro strings as code and return resolved expressions
      Hash resolved_values
      macro_strings.each do |macro_string|
        #marking up macro string for operators and unresolved parameters and stripping outer delimiters i.e. @(...)
        marked_up_macro_string = markup(markup(macro_string, @operator_hash.keys, '#'), /\b[a-z][_a-zA-Z0-9]*/, ':')[2...-1]
        #resolve marked up macro string and add cleaned up expression or value to hash
        resolved_values[macro_string] = eval_expr marked_up_macro_string
      end

      #change element's parameterized content to resolved expressions
      node.resolve_element resolved_values
    end
  end

  #take given macro strings and evaluates, returning resolved value - may still contain unresolved parameter expressions!
  #can we make this recursive so we don't have to worry about parentheses?
  def eval_expr macro_string
    #stack of operations (should not ever exceed 2!)
    operator_stack = []
    #last parameter found
    last_parameter_expr = ''
    #last value expression
    last_value_expr = ''
    #array of terms that come in two types: unsolvable (parameter expressions) and resolved expressions (value)
    expressions = []
    iterator = 0
    loop do
      case macro_string[iterator]
        #found a subexpression
        when '('
          #extract it - subtracting open and close parentheses
          sub_expr = macro_string[iterator + 1 ... find_close_parens_index(macro_string) - 1]
          #recurse to evaluate and replace with result
          resolved_sub_expr = eval_expr sub_expr
          #replace sub_expr plus parentheses with resolved sub_expr
          macro_string['(' + sub_expr + ')'] = resolved_sub_expr
          #bumping iterator up by length of replacement expression/value
          iterator += resolved_sub_expr.size
        #found an operator
        when '#'
          #find end of operator
          end_delimiter_index = macro_string[iterator+1...-1].find_index('#')
          operator = macro_string[iterator...end_delimiter_index]
          #we have a previous parameter
          if last_parameter_expr
            #add this operator to last parameter's expression and add to expressions
            expressions << last_parameter_expr + operator
            #empty last_parameter for next one
            last_parameter_expr.clear
          #we don't have a previous parameter
          else
            #push onto operator stack
            operator_stack << operator
          end
          #incrementing by size of operator
          iterator += operator.size
        #found a parameter
        when ':'
          #find end of parameter
          end_delimiter_index = macro_string[iterator+1...-1].find_index(':')
          #add each preceding operator before parameter
          operator_stack.each do |operator|
            last_parameter_expr += operator
          end
          #emptying stack
          operator_stack.clear
          #add parameter
          last_parameter_expr += macro_string[iterator...end_delimiter_index]
          #increment iterator by size of parameter
          iterator += last_parameter_expr.size
        #ignore whitespace
        when ' '
          #do nothing
        #found something other than an operator or parameter - must be an actual value; lots of code in common with parameter handling! combine somehow??
        else
          #empty parameter expression
          last_parameter_expr.clear
          #finding end of value (just before beginning of next operator)
          end_delimiter_index = macro_string[iterator...-1].find_index('#') - 1
          if last_value_expr
            #add each preceding operator before value to value expression
            operator_stack.each do |operator|
              last_value_expr += operator
            end
            #emptying stack
            operator_stack.clear
          end
          #adding the value we found
          last_value_expr += macro_string[iterator...end_delimiter_index]
          #we now have a resolvable expression - evaluate as code and convert to string
          result_str = eval(last_value_expr).to_s
          #overwrite expression with result
          macro_string[last_value_expr] = result_str
          #increment iterator by result's size
          iterator += result_str.size
          #set last_value_expr to result
          last_value_expr = result_str
      end
      iterator += 1
    end

  end

  #takes given string and, according to given criteria, marks various substrings with given delimiters
  def markup macro_string, *criteria, delimiter
    #go through each criteria string
    criteria.each do |criterion|
      #get array of matches
      macro_string.scan(criterion).each do |match|
        #add delimiter chars and spacing around each match
        macro_string[match] = ' ' + delimiter + match + delimiter + ' '
      end
    end
    macro_string
  end

  #what to do if Component consists of array of arrays?
  def instantiate current_node
    #look for if=false
    current_node.node_xpath.traverse do |node|
      if node['if'] == 'false'
        #remove the whole thing
        throw :deinstantiation
      end
      case node.name
        when 'instance'

          #find reference and import elements
          #pass on params
        when 'array'
        else
      end

    end
    ##if array loop and create concrete children
      #if instance load ref and iterate
  end
end

#Inspector takes queries, either from the Registry or user
#Registry queries include inspecting designs for changes and their validity upon commit, or generating analytics
module Inspector
  include Base_types
  #holds template for this inspector - children include rules that apply to this session
  @inspector_template

  def load_inspector inspector_template_file
    @inspector_template = Template.new inspector_template_file
  end

  #applies rules to given template and returns parts that qualify and errors for parts that don't
  def inspect open_template
    #traverse template
  end
end

include Base_types
#main program - actually a template that has as subsystems
class DesignOS < Template
  #our customization of option parser to convert program arguments into options
  require_relative 'option_parser'
  #Editor can be an XML editor or custom DesignOS interface but can also run in basic console mode (which underlies the other interfaces)
  include Editor
  #Builder constructs design from template, populating its children and applying parameter values
  include Builder
  #Inspector gets triggered by builder at certain points predetermined by OS and by user according to inputs
  include Inspector
  #the template that is called by the user
  alias_method :current_template, :doc

  def initialize *args
    #convert arguments into options
    options = Option_Parser.parse args
    super options.templates, options.user
    #load templates for each os module
    ['editor', 'builder', 'inspector'].each do |os_module|
      arg = @system.child(os_module)['ref']
      send ("load_#{os_module} #{arg}")
    end
    #start main loop
    main
  end

  #the main loop; default value is nil so process can listen for user input
  def main
    until Editor.exit?
      @current_template = inspect build edit @current_template
    end
  end
end

#BEGIN block
def BEGIN
  #set up user list access?
  #load GUI?
end

#main block
DesignOS.new

def END
  #save data?
  #update histories?
end
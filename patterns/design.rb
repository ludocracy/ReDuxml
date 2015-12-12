module Designs
  require_relative 'component/component'
  require_relative 'logic'

  include Components
  include Logics

  # instances are copies (dclones) or aliases (clones) of a given Component; if copies, they get Instances of the children also
  # when used to wrap a Component or set of Components, allows use of locally-namespaced parameters
  # when empty but given a target Component, creates copy and added as new child or creates alias and added as mirror child
  # wrapper is removed after build; aliases
  class Instance < Component
    # instances can expect reserved component element names AND parameter assignment hash
    def initialize xml_node, args = {}
      @reserved_word_array = %w(parameters array instance)
      super xml_node, args
    end

    def params
      parameters = find_child'parameters'
      if parameters
        parameters
      end
    end

    def param_val arg
      get_param_hash[arg]
    end
  end

  # part of the template file that actually contains the design or content
  # specifies logics allowed within itself
  class Design < Instance
    @logic
    @doc

    attr_reader :logic, :doc

    def initialize xml_node=nil, args = {}
      @xml_root_node = if xml_node.nil? || !xml_node.respond_to?(:element_children)
               generate_new_xml(xml_node, args) else xml_node
             end
      super xml
      # defining default logics here for now (make constant later? or builder template property?)
      if get_attr_val(:logics).nil?
        @attributes[:logics] = %w(logic)
      end

      get_attr_val(:logics).each do |logic|
        @logic = Logics::Logic.new(logic)
      end
    end

    private
    def generate_new_xml xml_node, args = {}
      return xml_node if xml_node.respond_to?(:element_children)
      new_doc = Nokogiri::XML(xml_node)
      new_doc << "<#{self.class.to_s.split('::').last.downcase}/>" if new_doc.element_children.empty?
      args.each do |key, val| new_doc.root[key]=val end
      @doc = new_doc
      new_doc.root
    end
  end

  # links function as aliases of a given Component; essentially they are the same object but in target location and location of Link object
  # actually implemented by redirecting pointers to target; Link Components must never have children!! any children added will be added to target!!
  class Link < Component
    def initialize xml_node, args = {}
      @reserved_word_array = []
      super xml_node, args
    end

    # is link live? links can be broken if the target object is removed after the link is created
    def link?
      true
    end
  end

  # name collision? doesn't seem like it...
  class ArrayInst < Instance
    include Enumerable
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def size
      get_attr_val :size
    end
  end
end

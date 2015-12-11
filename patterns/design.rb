module Patterns
  require_relative 'component/component'
  require_relative '../ext/object'

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
    attr_reader :logic

    def initialize xml_node=nil, args = {}
      generate_new_xml args if xml_node.nil?
      super xml
      # defining default logics here for now (make constant later? or builder template property?)
      if get_attr_val(:logics).nil?
        @attributes[:logics] = %w(logic)
      end

      get_attr_val(:logics).each do |logic|
        @logic = Logic.new(logic)
      end
    end

    def generate_new_xml args = {}
      doc = Nokogiri::XML::Document.new
      new_element = self.class.to_method_name
      @xml_root_node = Nokogiri::XML::Element.new(new_element, doc)
      @xml_cursor = @xml_root_node
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

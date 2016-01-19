require_relative 'component/component'
require_relative 'parameters'
require_relative 'logic'

module Patterns
  include Components

  # instances are copies (dclones) or aliases (clones) of a given Component; if copies, they get Instances of the children also
  # when used to wrap a Component or set of Components, allows use of locally-namespaced parameters
  # when empty but given a target Component, creates copy and added as new child or creates alias and added as mirror child
  # wrapper is removed after build; aliases
  class Instance < Component
    # instances can expect reserved component element names AND parameter assignment hash
    def initialize xml_node, args = {}
      super xml_node, reserved: %w(parameters array instance)
    end

    def params
      parameters = find_child 'parameters'
      if parameters
        parameters
      end
    end

    def param_val arg
      get_param_hash[arg]
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
  class Array < Instance
    include Enumerable
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def size
      get_attr_val :size
    end
  end
end

require_relative 'component/component'
require_relative 'parameters'
require_relative 'logic'

module Patterns
  include Components

  # wrapper is removed after build; aliases
  class Instance < Component
    # instances can expect reserved component element names AND parameter assignment hash
    def initialize xml_node, args = {}
      xml_node = %(<instance/>) if xml_node.nil?
      super xml_node, reserved: %w(parameters array instance)
    end

    def params
      find_child 'parameters'
    end

    def instantiate!
      if ref
        #target = id_or_uri?(ref) ? ObjectSpace._id2ref(ref) : Template.new(File.open(ref)).design
        #self << target.clone
      end
    end

    def ref
      self[:ref]
    end
  end

  class Design < Instance
    include Observable

    def initialize xml_node, args = {}
      #add_observer template.history
      super xml_node, args
    end

    def logics
      nil
    end
  end

  class Link < Component
    def initialize xml_node, args = {}
      super xml_node, args
    end


    def instantiate!
      ref = get_attr_val :ref
      target = id_or_uri?(ref) ? ObjectSpace._id2ref(ref) : Template.new(File.open(ref)).design
      self << target
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

    def instantiate!
      size_expr = size.respond_to?(:to_i) ? size.to_i : size.to_s
      if size_expr.is_a? Fixnum
        iterator = 0
        size_expr.times do
          i = Instance.new(nil)
          i << Parameters.new(nil, {iterator: iterator})
          children.each do |child| i << child.clone end
          self << i
          iterator += 1
        end
      end
    end

    def size
      self[:size]
    end

    def each &block
      @children.each &block
      self
    end
  end
end

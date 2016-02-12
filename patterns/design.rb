require_relative 'component/component'
require_relative 'parameters'
require_relative 'logic'

module Patterns
  include Components

  class Instance < Component
    def initialize xml_node=nil, args = {}
      xml_node = class_to_xml if xml_node.nil?
      super xml_node, reserved: %w(parameters array instance)
    end

    def params
      find_child 'parameters'
    end

    def instantiate target
      target.nil? ? self : target.clone
    end
  end

  class Design < Instance
    def logics
      true
    end
  end

  # links allow parameters to be bound to attribute values or element content in the design components wrapped by the link object
  class Link < Instance
    attr_reader :ref

    def instantiate target
      raise Exception if target.nil?
      @ref = target
    end
  end

  # name collision? doesn't seem like it...
  class Array < Instance
    include Enumerable

    def instantiate target
      return [] if target.nil?
      size_expr = size.respond_to?(:to_i) ? size.to_i : size.to_s
      if size_expr.is_a? Fixnum
        iterator_index = 0
        new_children = []
        size_expr.times do
          i = Instance.new
          i << Parameters.new(nil, iterator: iterator_index)
          if children.any?
            children.each do |child| i << child.clone end
          else
            i << target.clone
          end
          new_children << i
          iterator_index += 1
        end
        new_children
      else
        children
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

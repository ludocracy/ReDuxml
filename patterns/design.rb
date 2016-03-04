require_relative 'component/component'
require_relative 'parameters'
require_relative 'logic'

module Patterns
  include Components

  class Instance < Component
    def initialize xml_node=nil, args = {}
      xml_node = class_to_xml if xml_node.nil?
      super xml_node, reserved: %w(parameters array instance link)
    end

    def params
      p = find_child 'parameters'
      p.simple_class == 'parameters' ? p : []
    end

    def instantiate target_template=nil
      new_kids = []
      target = resolve_ref :ref, target_template
      if target.nil?
        children.each do |child|
          new_kids << child if child.simple_class != 'parameters'
        end
      else
        new_kid = target.clone
        new_kid.rename "#{id}.#{target.id}"
        new_kids << new_kid
      end
      new_kids
    end
  end

  class Design < Instance
    def instantiate
      [self]
    end

    def find_kansei target
      n = target.respond_to?(:name) ? target.name : target.to_s
      each do |node|
        return node if node.name == n
      end
      nil
    end
  end

  # links allow parameters to be bound to attribute values or element content in the design components wrapped by the link object
  class Link < Instance
    attr_reader :ref

    def instantiate target=nil
      resolve_ref nil, target
      self
    end
  end

  # name collision? doesn't seem like it...
  class Array < Instance
    include Enumerable

    def instantiate target_template=nil
      size_expr = size.respond_to?(:to_i) ? size.to_i : size.to_s
      if size_expr.is_a? Fixnum
        iterator_index = 0
        new_children = []
        kids = []
        children.each do |kid| kids << kid.detached_subtree_copy end
        remove_all!
        size_expr.times do
          i = Instance.new
          i << Parameters.new(nil, iterator: iterator_index)
          kids.each do |kid| i << kid.detached_subtree_copy end
          i.rename name+iterator_index.to_s
          new_children << i
          iterator_index += 1
        end
        new_children
      else
        []
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

# Copyright (c) 2016 Freescale Semiconductor Inc.
require 'con_duxml/instance'

module ConDuxml
  # XML object array
  # represents a pattern of copies of a this object's children or referents
  # differentiates between copies using iterator Parameter
  module Array
    include Instance

    # @return [Array[Element]] flattened array of all duplicated Elements
    def activate
      size_expr = size.respond_to?(:to_i) ? size.to_i : size.to_s
      if size_expr.is_a? Fixnum
        new_children = []
        size_expr.times do
          source_nodes = if nodes.empty? and self[:ref]
                           [resolve_ref.clone]
                         else
                           nodes.collect do |node| node.clone end
                         end
          source_nodes.each do |node|
            new_children << node
          end
        end
        new_children.flatten
      else
        [self]
      end
    end # def instantiate

    # size can be Fixnum or a Parameter expression
    def size
      self[:size]
    end
  end # class Array
end # module Dux
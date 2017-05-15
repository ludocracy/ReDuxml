# Copyright (c) 2016 Freescale Semiconductor Inc.
require 'ast'

module AST
  # redefining in order to allow type itself to be any type e.g. String, Symbol, Fixnum, etc.
  class Node
    include AST

    # The `properties` hash is passed to {#assign_properties}.
    def initialize(type, children=[], properties={})
      @type, @children = type, children.to_a.freeze

      assign_properties(properties)

      @hash = [@type.object_id, @children, self.class].hash

      freeze
    end

    # @param logic [Hash] hash of operators allowed in this AST containing each operator's print properties
    # @return [String] string reconstituted from polish-notation into notation normally required by each operator
    def print(logic=nil)
      return type.to_s if children.empty?
      str = ''
      op = type.respond_to?(:text) ? type : logic[type.to_s]
      return str unless op
      case op.position
        when :prefix
          str << op.symbol
          children.each do |c| str << c.print(logic) end
        when :postfix
          children.each do |c| str << c.print(logic) end
          str << op.symbol
        when :infix
          if op.arity > 2
            str << children.first.print(logic) << op.symbol << children[1].print(logic) << op.pair.symbol << children.last.print
          else
            str << (children.first.respond_to?(:print) ? children.first.print(logic) : children.first.symbol) << op.symbol << children.last.print
          end
        else # should not happen
      end
      str
    end # to_s
  end # class Node

  def new_ast(op, *obj)
    args = obj.collect do |o| o.is_a?(Node) ? o : Node.new(o) end
    args.unshift self if is_a?(Node)
    args.unshift Node.new(self) if is_a?(Fixnum)
    args.unshift Node.new(self) if self.is_a?(Symbolic::Variable)
    Node.new(op, args)
  end
end
# Copyright (c) 2016 Freescale Semiconductor Inc.
require_relative 'coerced'

module Symbolic
  include AST

  def %(var)
    return 0 if self.object_id == var.object_id
    return self % var if self.is_a?(Numeric) && var.is_a?(Numeric)
    new_ast :%, var
  end

  def -@(var)
    return -var unless var.is_a?(Node)
    return -var.type if var.type.is_a?(Numeric)
    reversed = var.type.reverse
    reversed ? new_ast(reversed, *var.children.dup) : new_ast(:-@, [var])
  end

  def not(var)
    return nil if var.is_a?(Symbolic::Variable)
    return !var unless var.is_a?(Node)
    inverted = var.type.inverse
    inverted ? new_ast(inverted, *var.children.dup) : new_ast(:!, [var])
  end
end

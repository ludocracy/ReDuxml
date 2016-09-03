# Copyright (c) 2016 Freescale Semiconductor Inc.
require_relative 'variable'

module Symbolic
  class Coerced
    include AST

    def %(numeric)
      numeric.new_ast(:%, @symbolic)
    end

    def **(numeric)
      numeric.new_ast(:**, @symbolic)
    end
  end
end
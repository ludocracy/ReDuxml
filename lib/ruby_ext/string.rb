# Copyright (c) 2016 Freescale Semiconductor Inc.
require 'duxml'

# extending String with #parameterized? and #balanced_parens? only to assist macro.rb
class String
  # returns whether or not contents include any Macro strings i.e. Parameter expressions
  def parameterized?
    self.include?('@(')
  end

  # returns whether number of open parentheses and close parentheses match
  def balanced_parens?
    self.match('(').size == self.match(')').size
  end
end # class String
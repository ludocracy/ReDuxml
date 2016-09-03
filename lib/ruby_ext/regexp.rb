# Copyright (c) 2016 Freescale Semiconductor Inc.
class Regexp
  # @return [Regexp] single and double quoted strings
  def self.string
    /['"][^'"]*['"]/
  end
end
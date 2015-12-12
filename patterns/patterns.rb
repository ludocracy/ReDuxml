require_relative 'template'
require_relative 'history'
require_relative 'design'
require_relative 'parameters'

module Patterns
  include Templates
  include Histories
  include Designs
  include Parameters
end
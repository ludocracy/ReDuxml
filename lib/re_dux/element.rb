require_relative 'element/parameterization'
require 'duxml'

module ReDuxml
  include Duxml

  class Element
    include Parameterization
  end
end
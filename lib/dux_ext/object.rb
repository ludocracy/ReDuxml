require File.expand_path(File.dirname(__FILE__) + '/../../../Dux/lib/dux/object')
require File.expand_path(File.dirname(__FILE__) + '/object/parameterization')

module Dux
  class Object
    include Parameterization
  end # class Dux
end
# Copyright (c) 2016 Freescale Semiconductor Inc.
require File.expand_path(File.dirname(__FILE__) + '/../symbolic_ext/variable')

module Duxml
  module Parameter; end

  # represents a parameter that can be used in any element's attribute values or text content
  # and is replaced with its value when validating an XML design
  class ParameterClass < ::Symbolic::Variable
    # Parameter can be initialized from XML Element or Ruby args
    # @param args[0] [String] must be name of Parameter
    # @param args[1] [String|Fixnum|Float|Boolean] can be starting value of Parameter
    # @param args[2] [String] can be description text of Parameter
    def initialize(name, value=nil)
      @name, @value = name, value
    end
  end # class Parameter

  module Parameter
    # @param val [String|Fixnum|Float|Boolean] changes value of Parameter and reports change
    def value=(val)
      if val != self[:value]
        old_val = self[:value]
        self[:value] = val
        report :change_attribute, {old_value: old_val, new_value: val, attr_name: 'value'}
      end
    end # def value=
  end
end # module Dux
require 'observer'
require_relative '../ext/object'
require_relative 'component/component'

module Patterns
  include Components

  class Parameters < Component
    include Enumerable

    def each &block
      children.each &block
    end

    def initialize xml_node=nil, args = {}
      if xml_node.nil?
        xml_node = class_to_xml
      end
      super xml_node, reserved: %w(parameter)
      args.each do |key, val| self << Parameter.new(nil, {name: key, value: val}) end if children.empty?
    end

    def [] target_key
      children.each do |param_node| return param_node[:value] if param_node[:name] == target_key.to_s  end
    end

    def << param
      raise Exception unless param.is_a?(Parameter)
      super param
    end
  end

  # specialization of Component holds parameter name, value and description
  # also, during Build, its abstracts and concretes track parameter value overrides
  class Parameter < Component
    include Observable

    def initialize xml_node, args={}
      if xml_node.nil?
        xml_node = class_to_xml
        xml_node[:name] = args[:name]
        xml_node[:value] = args[:value] if args[:value]
      end
      super xml_node, args
    end

    def value
      self[:value] || find_child(:string).content
    end

    # parameter value assignments must be recorded
    def value= val
      if val != self[:value]
        self[:value] = val
      end
    end
  end
end
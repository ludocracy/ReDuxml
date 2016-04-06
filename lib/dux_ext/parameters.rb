require File.expand_path(File.dirname(__FILE__) + '/object')

module Dux
  # container for all Parameter objects pertaining to this Instance
  class Parameters < Object
    include Enumerable

    # overriding #each to only traverse children
    def each(&block)
      children.each &block
    end

    # Parameters can be initialized from a Hash of parameter names and values
    def initialize(*args)
      super *args
      unless xml? args
        args.first.each do |key, val|
          @xml.remove_attribute key
          self << Dux::Parameter.new(key, val)
        end
      end
    end

    # overriding #[] to return parameter children as from a Hash
    # simply returns attribute hash if no argument given
    def [](target_key=nil)
      return xml.attributes if target_key.nil?
      children.each do |param_node| return param_node[:value] if param_node[:name] == target_key.to_s  end
    end

    # TODO replace with Rule?
    def << param
      raise Exception unless param.is_a?(Parameter)
      super param
    end
  end # class Parameters

  # represents a parameter that can be used in any element's attribute values or text content
  # and is replaced with its value when validating an XML design
  class Parameter < Object
    # Parameter can be initialized from XML Element or Ruby args
    # args[0] must be name of Parameter
    # args[1] can be starting value of Parameter
    # args[2] can be description text of Parameter
    def initialize(*args)
      super()
      unless xml? args
        self[:name] = args.first
        self[:value] = args[1] if args[1]
        self << args.last if args[2]
      end
    end

    # returns current value of Parameter
    def value
      self[:value] || find_child(:string).content
    end

    # changes value of Parameter and reports change
    def value=(val)
      if val != self[:value]
        old_val = self[:value]
        self[:value] = val
        report :change_attribute, {old_value: old_val, new_value: val, attr_name: 'value'}
      end
    end # def value=
  end # class Parameter
end # module Dux
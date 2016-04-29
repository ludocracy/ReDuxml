require File.expand_path(File.dirname(__FILE__) + '/object')

module Duxml
  # container for all Parameter objects pertaining to this Instance
  class Parameters < Object
    include Enumerable


    # Traverses each child node, yielding each to the specified block.
    #
    # @yieldparam node [Duxml::Parameter] Each parameter node.
    def each(&block)
      children.each &block
    end

    # @param args [Hash|Nokogiri::XML::Node] if args are not XML, given hash interpreted as parameter, value pairs to initialize new Duxml::Parameter children
    def initialize(*args)
      super *args
      unless xml? args
        args.first.each do |key, val|
          @xml.remove_attribute key
          self << Duxml::Parameter.new(key, val)
        end
      end
    end

    # overriding #[] to return parameter children as from a Hash
    #
    # @param key [Symbol|String] attempt to match Duxml::Parameter@name
    # @return [String|Hash] matching parameter's value or attributes as hash if no key given
    def [](key=nil)
      return xml.attributes if key.nil?
      children.each do |param_node| return param_node[:value] if param_node[:name] == key.to_s  end
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
    # @param args[0] [String] must be name of Parameter
    # @param args[1] [String|Fixnum|Float|Boolean] can be starting value of Parameter
    # @param args[2] [String] can be description text of Parameter
    def initialize(*args)
      super()
      unless xml? args
        self[:name] = args.first
        self[:value] = args[1] if args[1]
        self << args.last if args[2]
      end
    end

    # @return [String] current value of Parameter
    def value
      self[:value] || find_child(:string).content
    end

    # @param val [String|Fixnum|Float|Boolean] changes value of Parameter and reports change
    def value=(val)
      if val != self[:value]
        old_val = self[:value]
        self[:value] = val
        report :change_attribute, {old_value: old_val, new_value: val, attr_name: 'value'}
      end
    end # def value=
  end # class Parameter
end # module Dux
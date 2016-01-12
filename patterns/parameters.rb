require_relative '../ext/object'

module Parameters
  require_relative 'component/component'
  include Components

  class Parameters < Component
    def initialize xml_node, args = {}
      super xml_node, {reserved: ['parameter']}
      @parameter_hash = Hash.new
      children_hash['parameter'].each do |param| @parameter_hash[param[:name]] = param end
      update args unless args.nil? || args.empty?
    end

    def [] key
      @parameter_hash[key]
    end

    def update params
      h = Hash.new
      params.each do |key, val|
        h[key] = Parameter.new(
%(<parameter name="#{key}" value="#{val}"/>)
        )
      end
      @parameter_hash.merge!(h) do |key, old, new|
        # collect_changes last_change
        new
      end
    end
  end

  # specialization of Component holds parameter name, value and description
  # also, during Build, its abstracts and concretes track parameter value overrides
  class Parameter < Component
    def initialize xml_node, args={}
      super xml_node, args
    end

    def value
      self[:value]
    end

    # parameter value assignments must be recorded
    def value= val
      if val != self[:value]
        value = val
        throw :edit, Edit.new(nil, self)
      end
    end

    def describe
      self[:description]
    end
  end

  class Iterator < Parameter
    include Enumerable
    @offset
    @increment
    @symbol

    def array

    end

    def initialize node
      super node
      @offset = attributes[:offset]
      @increment = attributes[:increment]
      @symbol = attributes[:symbol]
    end
  end
end
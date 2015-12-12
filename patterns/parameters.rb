module Parameters
  require_relative 'component/component'
  include Components

  class Parameters < Component
    @reserved_word_array = 'parameter'
    def initialize xml_node, args = {}
      super xml_node
    end

    def parameter_hash
      @children_hash
    end

    def update params
      if params
        last_change = nil
        @children_hash.merge params.parameter_hash do |key, old_val, new_val|
          @children_hash[key] = new_val
          # last_change.push (catch :edit)
        end
        # collect_changes last_change
      end
    end
  end

  # specialization of Component holds parameter name, value and description
  # also, during Build, its abstracts and concretes track parameter value overrides
  class Parameter < Component
    def initialize xml_node, *args
      super xml_node, *args
    end

    def value
      self['value']
    end

    # parameter value assignments must be recorded
    def value= val
      if val != self[:value]
        value = val
        throw :edit, Edit.new(nil, self)
      end
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
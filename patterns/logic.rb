require_relative '../ext/symja'
require 'nokogiri'

module Patterns
  class Logic < Component
    # later this should load like a regular template (probably as part of inspector?)
    # then it will be a run time that listens for operations and reports performance
    def initialize logic_file_name
      @reserved_word_array = %w(operator)
      file = File.open("../../../DesignOS/xml/#{logic_file_name}.xml", 'r')
      xml_doc = Nokogiri::XML file
      #skipping straight to design
      #later we'll need to look at front matter of template to verify it; can't just load any old logic safely!
      super xml_doc.root.element_children[-1]
      @name = logic_file_name
      @resolver = Symja.new
    end

    # returns operator or operators that match arg; returns all if no arg
    def match_ops *args
      ops = []
      args.each do |arg|
        children.each do |operator|
          a = operator.match arg
          a ? ops << a : next
        end
      end
      args.empty? ? children : ops
    end

    # returns array of operator names starting in priority from the given symbol and working down if none found
    # in other words, this method will always return an array with an index for each operator,
    # the key is the pattern that constrains which operators' names are to be returned e.g. by type, inverse, etc.
    def aliases preferred_name, op_filter=nil
      a = []
      if op_filter then ary = match_ops(op_filter)
      else ary = match_ops
      end
      ary.each do |operator|
        case preferred_name
          when :regexp then a << operator.regexp
          when :symbol then a << operator.symbol
          else a << operator.aliases(preferred_name)[0]
        end
      end
      a.flatten
    end

    private

    # logics required for this logic to work i.e. definitions of these operations use operators defined in another logic
    def dependencies
      find_child('dependencies')
    end

  end # end of class Logic

  # container for every possible property of an operator
  class Operator < Component
    # any of the following can be used as a key to retrieve this operator
    # symbol that most commonly represents operator e.g. +,-
    @symbol
    # regexp used to find this operator in standard parameterized string
    @regexp
    # alternate name hash; keys are domains in which names are used
    @names

    attr_reader :symbol, :names, :regexp

    #returns names that match given symbols
    def aliases *keys
      a = []
      keys.each do |key|
        @names[key].nil? ? next : a << @names[key]
      end

      a.flatten
    end

    def const_name
      aliases(:default)[0].split(' ').each do |word| word.capitalize! end.join
    end

    def initialize xml_node
      super xml_node
      #zeroing out XML-derived properties because we're making our own structure
      remove_all!
      @attributes = {}
      xml_node.attributes.each do |name, attr| @attributes[name.to_sym] = (attr.value.is_a?(Array) ? attr.value[0] : attr.value) end
      # this name is guaranteed to be safe in any context (C-identifier string)
      @names = {safe: id}
      @id = id
      xml_node.element_children.each do |child|
        if child.name == 'names'
          child.element_children.each do |grandchild|
            sym = grandchild.name.to_sym
            case sym
              when :symbol then @symbol = grandchild.content.strip.to_sym
              when :regexp then @regexp = Regexp.new(grandchild.content.strip)
              else
                @names[sym] = grandchild.content
            end
          end
        else
          sym = child.name.to_sym
          @attributes[sym] = child.content.strip
        end
      end
      @regexp ||= @symbol.to_s
    end

  end # end of class Operator

end # end of module Patterns
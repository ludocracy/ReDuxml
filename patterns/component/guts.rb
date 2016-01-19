require 'nokogiri'

module Components
  module Guts
    private

    def collect_changes change
      cur = self.parent
      while cur
        if cur.is_a? Template
          cur.history.register_with_owner change
        end
        cur = cur.parent
      end
    end

    # loads methods to run during initialize from a hash
    def load_methods method_names
      method_hash = {}
      index = 0
      %w(top reserved traverse child).each do |key|
        method_name = method_names[index]
        if method_name
          our_method = method(method_names[index].to_sym)
        else
          our_method = method(:do_nothing)
        end
        method_hash[key.to_sym] = our_method
        index += 1
      end
      method_hash
    end

    # needed because i have to call a method and it has to have an argument
    def do_nothing arg = nil
      # this is silly
    end

    # should describe itself in a string
    def generate_descr

    end

    # run by initialize
    def traverse_xml method_hash
      method_hash[:top].call
      @xml_cursor.element_children.each do |child|
        if @reserved_word_array.include? child.name
          method_hash[:reserved].call child
        else
          if @xml_cursor.element_children.size == 1
            method_hash[:traverse].call child
          else
            method_hash[:child].call child
          end
        end
      end
    end

    # called by method hash when traversing down a Component's trailing XML descendants; its 'tail'
    def chase_tail child
      @xml_cursor = child
    end

    # adds leaf content as attribute; element name as key
    def load_content_if_leaf
      if @xml_cursor.element_children.size == 1
        @attributes[@xml_cursor.name] = @xml_cursor.content
      end
    end

    # child has a ruby class of its own
    def init_reserved child
      child_class = Patterns::const_get("#{self.class.to_s.split('::')[-2]+'::'}#{child.name.capitalize}")
      self << child_class.new(child)
    end

    # child is just XML - wrap it
    def init_generic child
      self << Component.new(child, {})
    end

    #takes an xml node's attributes and adds them to the Component's @attributes hash
    def load_attributes
      load_content_if_leaf
      @xml_cursor.attribute_nodes.each do |attr|
        key = attr.name.to_sym
        case key
          when :id || :name
            @id = attr.value
          when :visible
            @visible << " #{attr.value}"
          when :if
            @if << attr
          else
            @attributes[attr.name.to_sym] = attr.value
        end
      end
      if @id.nil?
        @id = self.object_id.to_s
      end
    end

    # traverses this Component's xml (and not children's) for parameterized content nodes
    def get_parameterized_xml_nodes
      @parameterized_nodes = {}
      traverse_xml load_methods ['find_parameterized_nodes', nil, 'chase_tail', nil]
      @parameterized_nodes
    end

    # looks through all attributes for parameter expressions
    def find_parameterized_nodes
      @if.each do |condition_node|
        add_if_parameterized condition_node
      end
      @attributes.each do |attr|
        add_if_parameterized attr
      end
    end

    # if a given attribute value is parameterized, add to hash with attribute node itself as key
    def add_if_parameterized attr
      if attr.respond_to(:value)
        value = attr.value
      else
        value = attr[1]
      end
      @parameterized_nodes[attr] = value if value.include? '@('
    end

    def xml=arg
      @xml_cursor=arg
    end

    def coerce obj
      case obj.class
        when String                                       then Components::Component.new(Nokogiri::XML(obj).root)
        when Nokogiri::XML::Element                       then Components::Component.new(obj)
        when obj.respond_to?(:document?) && obj.document? then Components::Component.new(obj.root)
        else obj
      end
    end
  end
end
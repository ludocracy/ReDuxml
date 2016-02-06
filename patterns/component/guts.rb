require 'nokogiri'
require_relative '../../ext/string'

module Components
  module Guts
    private
    # loads methods to run during initialize from a hash
    def load_methods method_names
      method_hash = {}
      index = 0
      %w(top reserved traverse).each do |key|
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
          method_hash[:traverse].call child
        end
      end
    end

    def load_parameterized_nodes
      return unless name=='design' || descended_from?(:design)
      xml_nodes = xml_root_node.attribute_nodes
      xml_root_node.children.each do |child|
        if child.is_a?(Nokogiri::XML::Node) && child.text?
          xml_nodes << child
          break
        end
      end
      xml_nodes.each do |xml_node| parameterized_nodes << xml_node if xml_node.content.parameterized? end
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
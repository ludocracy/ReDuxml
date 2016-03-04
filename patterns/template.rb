require_relative 'component/component'
require_relative 'history'
require_relative 'design'
require_relative 'grammar'

module Patterns
  include Components

  class Template < Component
    def initialize xml_node, args = {}
      xml_node = Nokogiri::XML File.open xml_node if xml_node.is_a?(String)
      xml_node = xml_node.root if xml_node.respond_to?(:root)
      super xml_node, reserved: %w(owners history grammar design)
    end

    def history
      find_child 'history'
    end

    def grammar
      find_child 'grammar'
    end

    def design
      find_child 'design'
    end

    def directives type=nil
      directive_array = find_child('directives').children
      return directive_array if type.nil?
      matching_directives = []
      directive_array.each do |child|
        generation_types = type.is_a?(Array) ? type : [type]
        matching_directives << child[:type] if generation_types.include?(child[:type])
      end
      matching_directives
    end

    def owners
      find_child('owners').children
    end
  end # end of Template class

  class Owners < Component
    def initialize xml_node, args={}
      super xml_node, reserved: %w(owner)
    end
  end

  class Owner < Component
    def initialize xml_node, args ={}
      super xml_node, args
    end
  end

end # end of module Patterns
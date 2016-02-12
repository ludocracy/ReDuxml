require_relative 'component/component'
require_relative 'history'
require_relative 'design'

module Patterns
  include Components

  class Template < Component
    def initialize xml_node, args = {}
      xml_node = xml_node.root if xml_node.respond_to?(:root)
      super xml_node, reserved: %w(owners history design)
    end

    def history
      find_child 'history'
    end

    def design
      find_child -1
    end

    def owners
      find_child('owners').children
    end

    def get_cutting
      cutting = Template.new(wrap current_node.design.xml)
    end
  end # end of Template class

  class Owners < Component
    def initialize xml_node
      super xml_node, reserved: %w(owner)
    end
  end

  class Owner < Component
    def initialize xml_node, args ={}
      super xml_node, args
    end

    def generate_new_xml args
      @xml_cursor
    end
  end

end # end of module Patterns
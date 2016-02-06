require_relative 'component/component'
require_relative 'history'
require_relative 'design'

module Patterns
  include Components

  # Templates are components that constitute a distinct technology
  # They must have owners and always record sub-component changes
  # Element names reserved by the template's schema rules become constructors for sub-components
  class Template < Component
    def initialize xml_node, args = {}
      xml_node = xml_node.root if xml_node.respond_to?(:root)
      super xml_node, reserved: %w(owners history design)
      # raise Exception if anything other than design has parameterization!!!
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

    def concrete cutting
      raise ArgumentError unless cutting.respond_to?(:design)
      @kanseis[cutting.design.params.to_hash] = cutting
      cutting.abstract self
    end

    def abstract trunk
      @abstraction = trunk
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
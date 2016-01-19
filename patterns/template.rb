require_relative 'component/component'
require_relative 'history'
require_relative 'design'

module Patterns
  include Components

  # Templates are components that constitute a distinct technology
  # They must have owners and always record sub-component changes
  # Element names reserved by the template's schema rules become constructors for sub-components
  class Template < Component
    # points to actual xml document. @xml_root_node points to the root element.
    @xml_doc
    # users or processes that created this template
    @owners

    def initialize template_root_node, args = {}
      # check for format - if non-compliant, wrap in boilerplate with DesignOS as owner
      super template_root_node, reserved: %w(owners history)
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

    def generate_new_xml args = {}
      @xml_doc = Nokogiri::XML::Document.new
      super
      @xml_doc << @xml_cursor
      @xml_root_node['visible'] = args[:owner].object_id.to_s
    end
  end # end of Template class

  class Owners < Component
    def initialize xml_node
      super xml_node, reserved: ['owner']
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
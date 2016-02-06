require 'singleton'
require_relative 'patterns/template'
require_relative 'ext/symja'
require_relative 'ext/macro'

module Patterns
  TEMPLATE_RELAXNG = 'C:\Users\b33791\RubymineProjects\DesignOS\rng\design.rng'
  class TreeFarm
    include Singleton

    @parameters
    @current_template
    @cursor

    attr_reader :current_template, :parameters, :cursor

    def load file
      xml = Nokogiri::XML File.read file
      xml = validate(xml) ? xml : wrap(xml)
      @current_template = Template.new(xml.root)
      @parameters = current_template.design.params
      current_template
    end

    # recursive method that traverses down system design, pruning and instantiating
    def grow current_node
      if current_node.respond_to?(:design)
        build = Template.new(wrap current_node.design.xml)
        @current_template.concrete build
        @current_template = build
        grow current_template.design
      else
        if current_node.respond_to?(:params) && current_node.params
          @parameters.update current_node.params

        end
        resolve! current_node
        #current_node.instantiate! if current_node.respond_to?(:params)
        dead_nodes = []
        current_node.children.each do |child|
          peek(child) ? grow(child) : dead_nodes << child
        end
        dead_nodes.each do |node| current_node.remove(node) end
      end
      current_template
    end

    private

    def peek current_node
      if current_node[:if].nil?
        true
      else
        r = resolve!(current_node, :if)
        r.if?
      end
    end

    def validate xml
      xml.root.name == 'template'
    end

    def wrap xml_node
      xml_doc = Nokogiri::XML(%(
      <template id="temp_id">
        <name>temp_name</name>
        <version>1.0</version>
        <owners>
          <owner id="chef_id">
            <name>module: Chef</name>
          </owner>
        </owners>
        <description>created by Chef module to wrap around non-DesignOS XML design</description>
      </template>
                              ))
      xml_doc.root << xml_node
      xml_doc
    end

    def resolve! current_node, attr=nil
      parameterized_xml_nodes = attr.nil? ? current_node.parameterized_nodes : [current_node.xml_root_node.attribute(attr.to_s)]
      parameterized_xml_nodes.each do |xml_node|
        content_str = xml_node.content.to_s
        question = find_expr content_str
        reply = Macro.new Symja.instance.evaluate(question, parameters)
        replacement_str = reply.parameterized? ? reply : reply.demacro
        xml_node.content = content_str.gsub(Macro.new(question), replacement_str)
      end
      #parameterized_xml_nodes.empty? ? current_node : current_node.concrete!
      current_node
    end

    def find_expr str
      expr_start_index = str.index('@(')
      return str if expr_start_index.nil?
      expr_end_index = find_close_parens_index str[expr_start_index+1..-1]
      str[expr_start_index+2, expr_end_index-1]
    end

    def find_close_parens_index str
      levels = 0
      index = 0
      str.each_char do |char|
        case char
          when '(' then levels += 1
          when ')' then levels -= 1
          else
        end
        return index if levels == 0
        index += 1
      end
      raise Exception, "cannot find end of parameter expression!"
    end

  end
end
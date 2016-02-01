require 'java'
require 'singleton'
require_relative 'patterns/template'

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
      @parameters.update cursor.params if cursor.respond_to?(:params)
      if current_node.respond_to?(:design)
        @cursor = current_node.design
        @current_template.graft Template.new(wrap cursor)
        @current_template = current_template.kanseis.first
      else
        kansei_node = resolve(current_node)
        current_node.children.each do |child|
          if peek(child)
            kansei_node << grow(child)
          else
            current_node.remove child
          end
        end
      end
    end

    private

    def peek current_node
      if current_node[:if]
        return resolve current_node[:if]
      end
      true
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
                              ))
      xml_doc.root << xml_node.root
      xml_doc
    end

    def resolve current_node
      working_node = current_node.clone
      working_node.get_parameterized_xml_nodes.each do |xml_node|
        # check for if statement first!!!
        content_str = xml_node.content.to_s
        question = find_expr content_str
        reply = Symja.evaluate(question, parameters)
        xml_node.content = content_str.gsub(question, reply)
      end
      working_node
    end

    def find_expr str
      expr_start_index = str.index'@('
      expr_end_index = find_close_parens_index str[expr_start_index,-1]
      str[expr_start_index, expr_end_index]
    end

    def find_close_parens_index str
      levels = 0
      str.to_ary.each_with_index do |char|
        if index == 0
          levels += 1
          next
        end
        case char
          when '(' then levels += 1
          when ')' then levels -= 1
          else next
        end
        return index if levels == 0
      end
      raise Exception, "cannot find end of parameter expression!"
    end
  end
end
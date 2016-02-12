require File.expand_path(File.dirname(__FILE__) + '/tree_farmer.rb')
require_relative 'ext/nokogiri'
require_relative 'patterns/template'
require_relative 'ext/symja'
require_relative 'ext/macro'

module Patterns
  #TEMPLATE_RELAXNG = 'C:\Users\b33791\RubymineProjects\DesignOS\rng\design.rng'
  class TreeFarm
    include TreeFarmer
    @parameters_stack
    @kansei_array
    @ref_component_hash

    attr_reader :kansei_array, :parameters_stack, :ref_component_hash
  private
    def initialize file=""
      @parameters_stack = []
      @kansei_array = []
      @ref_component_hash = {}
      plant file if File.exists? file
    end

    def update_params! current_node
      if current_node.respond_to?(:params) && current_node.params
        current_node.params.each do |param|
          resolve_parameterized!(param, :value) if param.value.parameterized?
          param.xml_root_node[:if] = 'false' unless param.value.parameterized?
          overriding_param = parameter_hash[param[:name]]
          update param, overriding_param if overriding_param
        end
        if current_node.params.any?
          @parameters_stack << current_node.params
          true
        else
          false
        end
      else
        false
      end
    end

    def instantiate! current_node
      if current_node.respond_to?(:params)
        if current_node.params && !current_node.params.children.any? do |child| child.if? end
          current_node.remove current_node.params
        end
        return current_node.children if current_node.respond_to?(:logics)
        parent_node = current_node.parent
        ref_target = resolve_ref current_node
        current_node.instantiate(ref_target).each do |new_node|
          parent_node << new_node
        end
        parent_node.remove current_node
        parent_node.children
      else
        current_node.children
      end
    end

    def resolve_parameterized! current_node, attr=nil
      parameterized_xml_nodes = attr.nil? ? current_node.parameterized_nodes : [current_node.xml_root_node.attribute(attr.to_s)]
      parameterized_xml_nodes.each do |xml_node|
        content_str = xml_node.content.to_s
        question = find_expr content_str
        h = parameter_hash
        reply = Macro.new Symja.instance.evaluate(question, parameter_hash)
        replacement_str = reply.parameterized? ? reply : reply.demacro
        xml_node.content = content_str.gsub(Macro.new(question), replacement_str)
      end
      #parameterized_xml_nodes.empty? ? current_node : current_node.concrete!
      current_node
    end

    def parameter_hash
      h = {}
      parameters_stack.reverse.each do |params|
        params.each do |param| h[param[:name].to_sym] = param[:value] end
      end
      h
    end

    def resolve_ref instance_node
      return nil unless ref = instance_node[:ref]
      ref.match(Regexp.identifier) ? ref_component_hash[ref] : Template.new(File.open(ref)).design
    end

    def peek current_node
      if current_node[:if].nil? || current_node.simple_class.include?('parameter')
        true
      else
        r = resolve_parameterized!(current_node, :if)
        r.if?
      end
    end

    def update before, after
      # record in history
    end

    def validate xml
      xml.root.name == 'template'
    end

    def wrap xml_node
      raise ArgumentError unless instance_id = xml_node[:id]
      xml_doc = Nokogiri::XML(%(
      <template id="#{instance_id}">
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
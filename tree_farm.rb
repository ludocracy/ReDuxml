require File.expand_path(File.dirname(__FILE__) + '/tree_farm_interface.rb')
require_relative 'ext/nokogiri'
require_relative 'patterns/template'
require_relative 'ext/symja'
require_relative 'ext/macro'

module Patterns
  #TEMPLATE_RELAXNG = 'C:\Users\b33791\RubymineProjects\DesignOS\rng\design.rng'
  class TreeFarm
    include TreeFarmInterface
    @kansei_array

    attr_reader :kansei_array
  private
    def initialize file=""
      @kansei_array = []
      plant file if File.exists? file
    end

    def instantiate! current_node
      if current_node.respond_to?(:params)
        ref_target = resolve_ref current_node
        current_node.instantiate(ref_target).each do |new_node|
          current_node << new_node unless new_node.parent === current_node
        end
      end
    end

    def grow! current_node=nil
      if current_node.nil?
        add_kansei base_template.design
        current_template.rename 'grown'
        grow! current_template.design
      else
        resolve_parameterized! current_node
        current_node.children.each do |child|
          if peek child
            instantiate! child
            grow! child
          end
        end
      end
    end

    def previous
      kansei_array[-2]
    end

    def prune!
      add_kansei current_template.design.stub
      current_template.rename 'pruned'
      previous.design.each do |node|
        next if reserved_node?(node)
        ref_parent = find_non_inst_ancestor node
        new_parent = current_template.design.find_kansei ref_parent
        new_kid = node.stub
        begin
          new_parent << new_kid
        rescue RuntimeError
          new_id = "#{new_kid.id}.#{node.parent.id}"
          new_kid.rename new_id
          retry
        end
      end
    end

    def find_non_inst_ancestor node
      cur = node.parent
      return if cur.nil?
      if cur.respond_to?(:params) &&
          cur.simple_class != 'design'
        find_non_inst_ancestor cur
      else
        cur
      end
    end

    def reserved_node? node
      node.descended_from?('parameters') || node.simple_class == 'parameters' ||
        node.simple_class == 'design' || dead_node?(node) || node.respond_to?(:params)
    end

    def dead_node? node
      cur = node
      until cur.simple_class == 'design'
        return true unless cur.if?
        cur = cur.parent
      end
      false
    end

    def add_kansei design
      @kansei_array << Template.new(wrap design.xml)
    end

    def resolve_parameterized! current_node, attr=nil
      parameterized_xml_nodes = if attr.nil?
                                  current_node.parameterized_nodes
                                else
                                  [current_node.xml_root_node.attribute(attr.to_s)]
                                end
      parameterized_xml_nodes.each do |xml_node|
        content_str = xml_node.content.to_s
        question = find_expr content_str
        next if question.nil?
        h = get_param_hash current_node
        reply = Macro.new Symja.instance.evaluate(question, h)
        replacement_str = reply.parameterized? ? reply : reply.demacro
        macro_string = Macro.new(question)
        xml_node.content = content_str.gsub(macro_string, replacement_str)
      end
      #parameterized_xml_nodes.empty? ? current_node : current_node.concrete!
      current_node
    end

    def get_param_hash comp
      h = {}
      inst_hierarchy = get_inst_hierarchy comp
      inst_hierarchy.each do |inst|
        if inst.params && inst.params.any?
          inst.params.each do |param|
            next unless param[:name]
            h[param[:name].to_sym] = param[:value]
          end
        end
      end
      h
    end

    def get_inst_hierarchy node
      h = []
      node.parentage.each do |ancestor|
        h << ancestor if ancestor.respond_to?(:params)
      end
      h
    end

    def resolve_ref instance_node
      return nil unless ref = instance_node[:ref]
      ref.match(Regexp.identifier) ? base_template.design.find_kansei(ref) : Template.new(File.open(ref)).design
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

    def wrap xml_node=nil
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
      xml_doc.root << xml_node if xml_node = xml_node.xml
      xml_doc
    end

    def find_expr str
      expr_start_index = str.index('@(')
      return nil if expr_start_index.nil?
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
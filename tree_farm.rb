require File.expand_path(File.dirname(__FILE__) + '/tree_farm_hand.rb')
require File.expand_path(File.dirname(__FILE__) + '/tree_farm_interface.rb')
require_relative 'ext/symja'
require_relative 'ext/macro'

module Patterns
  #TEMPLATE_RELAXNG = 'C:\Users\b33791\RubymineProjects\DesignOS\rng\design.rng'
  class TreeFarm
    include TreeFarmHand
    include TreeFarmInterface
    @kansei_array

    attr_reader :kansei_array
    private

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

    def resolve_parameterized! current_node, attr=nil
      parameterized_xml_nodes = if attr.nil?
                                  current_node.parameterized_xml_nodes
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



  end
end
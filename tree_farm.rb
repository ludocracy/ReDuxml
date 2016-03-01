require File.expand_path(File.dirname(__FILE__) + '/tree_farm_hand.rb')
require File.expand_path(File.dirname(__FILE__) + '/tree_farm_interface.rb')

module Patterns
  #TEMPLATE_RELAXNG = 'C:\Users\b33791\RubymineProjects\DesignOS\rng\design.rng'
  class TreeFarm
    include TreeFarmHand
    include TreeFarmInterface
    @kansei_array
    @cursor

    attr_reader :kansei_array
    private

    # does the same thing as grow but applies not to design but to directives
    # - applies parameterization (separate domain!)
    # - instantiates output objects
    # - returns new xml tree as another kansei
    def harvest! current_node=nil
      if current_node.nil?
        add_kansei
        current_template.rename 'harvested'
        harvest! current_template.directives
      else
        current_node
      end
    end

    def instantiate! current_node
      @cursor = current_node
      if current_node.respond_to?(:params)
        ref_target = resolve_ref current_node[:ref]
        current_node.instantiate(ref_target).each do |new_node|
          unless current_node.find_child(new_node.id) || current_node.id == new_node.id
            current_node << new_node
          end

        end
      end
    end

    def grow! current_node=nil
      @cursor = current_node
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
      @cursor = current_node
      parameterized_xml_nodes = if attr.nil?
                                  current_node.parameterized_xml_nodes
                                else
                                  [current_node.xml_root_node.attribute(attr.to_s)]
                                end
      parameterized_xml_nodes.each do |xml_node|
        param_hash = get_param_hash current_node
        content_str = xml_node.content.to_s
        xml_node.content = resolve_str content_str, param_hash
      end
      current_node
    end # def resolved_parameterized!

    def prune!
      add_kansei current_template.design.stub
      current_template.rename 'pruned'
      previous.design.each do |node|
        next if reserved_node?(node)
        ref_parent = find_non_inst_ancestor node
        new_parent = current_template.design.find_kansei ref_parent
        @cursor = new_parent
        new_kid = node.stub
        begin
          new_parent << new_kid
        rescue RuntimeError
          new_id = "#{new_kid.id}.#{node.parent.id}"
          new_kid.rename new_id
          retry
        end
      end # previous.design.each do
    end # def prune!
  end # class TreeFarm
end # module Patterns
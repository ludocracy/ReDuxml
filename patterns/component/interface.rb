require 'observer'
require_relative '../../ext/macro'

module Components
  module Interface
    include Observable
    include Comparable

    def <=> comp
      case size <=> comp.size
        when -1 then -1
        when 0 then xml_root_node.size <=> comp.xml_root_node.size
        when 1 then 1
      end
    end

    def is_component?
      true
    end

    def promote attr_key, args={}
      new_name = args[:element] || attr_key.to_s
      if !args[:attr].nil?
        new_attr = args[:attr] || attr_key.to_s
        new_val = args[:value] || self[attr_key]
        s_string = "<#{new_name.to_s} #{new_attr}=\"#{new_val}\"/>"
      else
        new_content = args[:content] || self[attr_key]
        s_string = "<#{new_name}>#{new_content}</#{new_name}>"
      end
      new_comp = Component.new(s_string)
      self << new_comp
      @xml_root_node.remove_attribute attr_key.to_s
      new_comp
      report :edit, attr_key.to_sym => ''
    end

    def to_s
      @xml_root_node.to_s
    end

    def detached_subtree_copy
      new_node = detached_copy
      children.each do |child|
        new_node << child.detached_subtree_copy
      end
      new_node
    end

    def parameterized_xml_nodes
      return unless type=='design' || descended_from?(:design)
      xml_nodes = xml_root_node.attribute_nodes
      xml_root_node.children.each do |child|
        if child.is_a?(Nokogiri::XML::Node) && child.text?
          xml_nodes << child
          break
        end
      end
      a = []
      xml_nodes.collect do |xml_node| a << xml_node if xml_node.content.parameterized? end
      a
    end

    def type
      xml_root_node.name
    end

    def stub
      x = xml.dup
      x.element_children.remove
      self.class.new x
    end
    alias_method :detached_copy, :stub

    def summarize
      content = ""
      if @children.size != 0
        content = "children: "
        @children.each do |child|
          content << "'#{child.name}' "
        end
      else
        content = "content: #{self.content}"
      end
      puts "Component '#{name}' #{content}"
    end

    def if?
      return true unless if_str = xml_root_node[:if]
      if_str.parameterized? || if_str == 'true' ? true : false
    end

    def find_children type
      a = []
      children.each do |child| a << child if child.type == type.to_s end
      a
    end

    def find_child child_pattern, cur_comp = nil
        pattern = if child_pattern.is_a?(Array)
                    child_pattern.any? ? child_pattern.first : nil
                  else
                    child_pattern
                  end
      return nil unless pattern
      #attempting to match by name
      cur_comp ||= self
      #attempting to use pattern as index
      return cur_comp.children[pattern] if pattern.is_a?(Fixnum)
      cur_comp.children.each do |cur_child|
        if cur_child.name == pattern.to_s || cur_child.type == pattern.to_s
          if child_pattern == pattern || child_pattern.size == 1
            return cur_child
          else
            return find_child(child_pattern[1..-1], cur_child)
          end
        end
      end
      #attempting to use pattern as key
      if cur_comp.children_hash[pattern]
        cur_comp.children_hash[pattern]
      else
        find_child(child_pattern[1..-1]) if child_pattern.is_a?(Array)
      end
      nil
    end #def find_child

    # overriding TreeNode::content to point to XML head's content
    def content
      xml_root_node.content
    end

    def id
      self[:id]
    end

    def [] attr=nil
      attr.nil? ? xml_root_node.attributes : xml_root_node[attr.to_s]
    end

    def each &block
      super &block
    end

    def << obj
      objs = obj.is_a?(Array) ? obj : [obj]
      objs.each do |node|
        new_kid = coerce node
        add new_kid
        @xml_cursor.add_child new_kid.xml_root_node
        report :insert, node if design_comp?
      end
    end

    # should we add a remove array function?
    def remove child_or_id
      return if child_or_id.nil?
      child = child_or_id.respond_to?(:id) ? child_or_id : find_child(child_or_id)
      child.xml_root_node.remove
      remove! child
      report :remove, child
    end

    def []= key, val
      change_attr_value key, val
    end

    def if= condition
      # check for valid conditional
      change_attr_value :if, condition
    end

    def rename new_id
      old_id = id
      super new_id
      @xml_root_node[:id] = new_id
      report :change_attribute, {id: old_id} if design_comp?
    end

    def content= new_content
      change_type = content.empty? ? :new_content : :change_content
      old_content = content
      @xml_root_node.content = new_content
      report change_type, old_content
    end

    def descended_from? target
      xml_root_node.ancestors.each do |ancestor|
        return true if ancestor.name == target.to_s
      end
      false
    end

    def instance
      parentage.each do |ancestor| return ancestor if ancestor.respond_to?(:params) end
      nil
    end

    def template
      return root if root.type == 'template'
      nil
    end
  end
end
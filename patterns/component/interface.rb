require 'observer'
require_relative '../../ext/macro'

module Components
  module Interface
    include Observable

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
      a = []
      xml_nodes = xml_root_node.attribute_nodes
      xml_root_node.children.each do |child|
        if child.is_a?(Nokogiri::XML::Node) && child.text?
          xml_nodes << child
          break
        end
      end
      xml_nodes.each do |xml_node| a << xml_node if xml_node.content.parameterized? end
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

    # finds first near match child
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
    end

    # overriding TreeNode::content to point to XML head's content
    def content
      xml_root_node.content
    end

    def content= arg
      @content = arg
      @xml_root_node.content = arg
    end

    def id
      self[:id]
    end

    def [] attr
      xml_root_node[attr.to_s]
    end

    def each &block
      super &block
    end

    # need to have observer monitor this method!!!
    def << obj
      objs = obj.is_a?(Array) ? obj : [obj]
      objs.each do |node|
        new_kid = coerce node
        add new_kid
        @xml_cursor.add_child new_kid.xml_root_node
      end
      #update history
    end

    # need to have observer monitor this method!!!
    def remove child
      return if child.nil? || !child.any?
      child.xml_root_node.remove
      remove! child
      #update history
    end

    def rename new_id
      super new_id
      @xml_root_node[:id] = new_id
    end

    def descended_from? target
      xml_root_node.ancestors.each do |ancestor|
        return true if ancestor.name == target.to_s
      end
      false
    end
  end
end
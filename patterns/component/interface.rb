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

    # only for testing purposes! otherwise xml nodes should always have their children with them
    def stub
      x = xml.clone
      x.element_children.remove
      x
    end

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
      if_expr = Macro.new(if_str)
      if_expr.parameterized? || if_expr == 'true' ? true : false
    end

    # finds first near match child
    def find_child child_pattern, cur_comp = nil
      return nil unless child_pattern
      pattern = child_pattern.is_a?(Array) ? child_pattern.first : child_pattern
      #attempting to match by name
      cur_comp ||= self
      cur_comp.children.each do |cur_child|
        if cur_child.name == pattern.to_s || cur_child.type == pattern.to_s
          if child_pattern == pattern || child_pattern.size == 1
            return cur_child
          else
            return find_child(child_pattern[1..-1], cur_child)
          end
        end
      end
      #attempting to use pattern as index
      cur_comp.children[pattern]
    rescue TypeError
      #attempting to use pattern as key
      if cur_comp.children_hash[pattern]
        cur_comp.children_hash[pattern].first
      else
        find_child(child_pattern[1..-1])
      end
    end

    # overriding TreeNode::content to point to XML head's content
    def content
      xml_root_node.content
    end

    def id
      self[:id]
    end

    def [] attr
      xml_root_node[attr.to_s]
    end

    # need to have observer monitor this method!!!
    def << obj
      c = coerce(obj)
      add c
      @xml_cursor.add_child c.xml_root_node
      #update history
    end

    # need to have observer monitor this method!!!
    def remove child
      child.xml_root_node.remove
      remove! child
      #update history
    end

    def descended_from? target
      xml_root_node.ancestors.each do |ancestor|
        return true if ancestor.name == target.to_s
      end
      false
    end
  end
end
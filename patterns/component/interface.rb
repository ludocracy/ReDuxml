module Components
  module Interface
    def promote attr_key, args={}
      new_name = args[:element] || attr_key.to_s
      if !args[:attr].nil?
        new_attr = args[:attr] || attr_key.to_s
        new_val = args[:value] || @attributes[attr_key]
        s_string = "<#{new_name.to_s} #{new_attr}=\"#{new_val}\"/>"
      else
        new_content = args[:content] || @attributes[attr_key]
        s_string = "<#{new_name}>#{new_content}</#{new_name}>"
      end
      new_comp = Component.new(s_string)
      self << new_comp
      @attributes.delete self[attr_key]
      @xml_root_node.remove_attribute attr_key.to_s
      new_comp
    end

    def graft cutting
      @kanseis.push cutting
    end

    def to_s
      @xml_root_node.to_s
    end

    def stub
      x = xml.clone
      x.element_children.remove
      Component.new(x)
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

    # traverses this Component's xml (and not children's) for parameterized content nodes
    def get_parameterized_xml_nodes
      @parameterized_nodes = {}
      traverse_xml load_methods ['find_parameterized_nodes', nil, 'chase_tail', nil]
      @parameterized_nodes
    end

    # finds first near match child
    def find_child child_pattern, cur_comp = nil
      return nil unless child_pattern
      pattern = child_pattern.is_a?(Array) ? child_pattern.first : child_pattern
      #attempting to match by name
      cur_comp ||= self
      cur_comp.children.each do |cur_child|
        if cur_child.name == pattern.to_s
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
      cur_comp.children_hash[pattern] || find_child(child_pattern[1..-1])
    end

    # overriding TreeNode::content to point to XML head's content
    def content
      xml.content
    end

    # initializes component attributes if empty
    def []= attr, *vals
      @attributes[attr] ||= vals.join(' ')
      @xml_cursor[attr] ||= vals.join(' ')
    end

    def [] attr
      attributes[attr]
    end

    def << obj
      c = coerce(obj)
      add c
      @xml_cursor.add_child c.xml_root_node
    end

    def remove child
      child.xml_root_node.remove
      remove! child
    end
  end
end
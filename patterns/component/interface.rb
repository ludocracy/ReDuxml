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

    def to_s
      @xml_root_node.to_s
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

    # finds first near match child
    def find_child child_pattern
      #attempting to match by name
      @children.each do |cur_child|
        return cur_child if cur_child.name == child_pattern.to_s
      end
      #attempting to use pattern as index
      @children[child_pattern]
    rescue TypeError
      #attempting to use pattern as key
      @children_hash[child_pattern] || self
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
  end
end
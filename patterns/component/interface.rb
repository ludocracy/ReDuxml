module Components
  module Interface
    # creates new XML element
    def element name, content=nil
      new_element = Nokogiri::XML::Element.new(name.to_s, document)
      new_element = new_element.root unless new_element.is_a?(Nokogiri::XML::Element)
      if content.is_a?(Hash)
        content.each do |key, value|
          new_element[key.to_s.strip]=value.to_s.strip
          @attributes[key]=value
        end
      elsif !content.nil?
        new_element.content = content
      end
      new_element
    end

    # shortcut
    def xml
      @xml_root_node
    end

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
      new_comp = Patterns::Component.new(s_string)
      self << new_comp
      @attributes.delete self[attr_key]
      @xml_root_node.remove_attribute attr_key.to_s
      new_comp
    end

    def give_attribute! attr_key, target
      target[attr_key] = self[attr_key]
      self[attr_key] = nil
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

    def view view_hash
      if reconcile view_hash, @visible
        # @views[view_hash] = @cursor.dup
      end
    end

    def reconcile view_hash, visible
      visible.split(' ').each do |view|
        true if view_hash.include? view
      end
      false
    end

    # finds first near match child
    def find_child child_pattern
      #attempting to match by name
      @children.each do |cur_child|
        return cur_child if cur_child.name == child_pattern
      end
      #attempting to use pattern as index
      @children[child_pattern]
    rescue TypeError
      #attempting to use pattern as key
      @children_hash[child_pattern]
    end

    # a slightly safer way to get an attribute's final value (read only)
    def get_attr_val attr
      @attributes[attr]
    end

    def children?
      @children.size.to_s
    end

    # overriding TreeNode::content to point to XML head's content
    def content
      xml.content
    end

    # initializes component attributes if empty
    def []= attr, *vals
      @attributes[attr] ||= vals.join ' '
      @xml_cursor[attr] ||= vals.join ' '
    end

    def [] attr
      get_attr_val attr
    end

    # extending TreeNode's add child to link up XML if for new node
    def << component_child
      x = component_child.xml
      unless x.respond_to?(:add_child)
        @xml_cursor.add_child component_child.xml unless @xml_cursor.element_children.any? do |match| match==x end
      end
      super component_child
    end
  end
end
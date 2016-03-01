require_relative 'component/component'
require_relative '../tree_farm_hand'

module Patterns
  include Components

  class History < Component
    include Enumerable

    def initialize xml_node=nil, args={}
      xml_node = %(<history><insert id="change_0" owner="system"><description>file created</description><date>#{Time.now.to_s}</date></insert></history>) if xml_node.nil?
      super xml_node, reserved: %w(insert remove change_content change_attribute new_content new_attribute error correction instantiate move undo)
    end

    def update type, change
      change_class = Patterns::const_get type.to_s.classify
      change_comp = change_class.new(nil, change)
      add change_comp, 0
      @xml_root_node.prepend_child change_comp.xml
    end

    def each &block
      children.each &block
    end

    def last
      last_child
    end

    def [] key
      find_child key
    end
  end

  # individual change; not to be used, only for subclassing
  class Change < Component
    include TreeFarmHand

    def initialize xml_node, args = {}
      if xml_node.nil?
        xml_node = class_to_xml
        xml_node[:date] = Time.now.to_s
        args.each do |key, val|
          if val.is_a?(Hash)
            val.each do |k, v| xml_node << element(k.to_s, nil, v) end
          else
            xml_node << element(key.to_s, nil, val)
          end
        end
      end
      super xml_node, args
    end

    def description
      descr = find_child(:description)
      descr.nil? ? nil : descr.content
    end

    def date
      self[:date]
    end

    def affected_parent
      resolve_ref find_child(:parent).content
    end

    def base_template
      root
    end

    def target
      targe = find_child(:target)
      targe = targe.children.first if targe.has_children?
      targe
    end
  end

  class Remove < Change
    def description
      super || %(Component '#{removed.id}' of type '#{removed.type}' was removed from component '#{affected_parent.id}' of type '#{affected_parent.type}'.)
    end

    def removed
      find_child(:target).children.first
    end
  end

  class Insert < Change
    def description
      super || %(Component '#{inserted.id}' of type '#{inserted.type}' was added to component '#{affected_parent.id}' of type '#{affected_parent.type}'.)
    end

    def inserted
      resolve_ref find_child(:target).content
    end
  end

  class Edit < Change
    def description
      super if super
    end
  end

  class ChangeContent < Edit
    def description
      super
      "Component '#{affected_parent.id}' of type '#{affected_parent.type}' changed content from '#{old_content}' to '#{new_content}'."
    end

    def old_content
      target.content
    end

    def new_content
      affected_parent.content
    end
  end

  class ChangeAttribute < Edit
    def description
      super
      "Component '#{affected_parent.id}' of type '#{affected_parent.type}' changed attribute '#{attr_name}' value from '#{old_value}' to '#{new_value}'."
    end

    def old_value
      find_child(:old_value).content
    end

    def new_value
      affected_parent[attr_name.to_sym]
    end

    def attr_name
      find_child(:attr_name).content
    end
  end

  class NewContent < Edit

    def description
      super
      "Component '#{affected_parent.id}' of type '#{affected_parent.type}' given new content '#{new_content}'."
    end

    def new_content
      affected_parent.content
    end
  end

  class NewAttribute < Edit
    def description
      super
      "Component '#{affected_parent.id}' of type '#{affected_parent.type}' given new attribute '#{new_attr_name}' with value '#{new_attr_value}'."
    end

    def new_attr_name
      find_child(:attr_name).content
    end

    def new_attr_value
      find_child(:new_value).content
    end
  end

  class Undo < Change
    def description
      super || "#{target_full_name} removed from #{parent_full_name}."
    end

    def undone_change
      self[:change]
    end
  end

  class Error < Change
    def description
      super || "#{target_full_name} removed from #{parent_full_name}."
    end
  end
end # end of module Patterns
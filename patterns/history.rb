require_relative 'component/component'
require_relative '../tree_farm_hand'

module Patterns
  include Components

  class History < Component
    include Enumerable

    def initialize xml_node=nil, args={}
      xml_node = %(<history><insert id="change_0" owner="system"><description>file created</description><date>#{Time.now.to_s}</date></insert></history>) if xml_node.nil?
      super xml_node, reserved: %w(insert remove edit error correction instantiate move undo)
    end

    def update type, change
      change_class = Patterns::const_get type.to_s.capitalize
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
        args.each do |key, val|
          case
            when val.respond_to?(:id) then xml_node << val.xml
            when val.is_a?(Hash)
              old_content_str = val.first.last.empty? ? nil : val.first.last
              old_content_type = val.first.first.to_s
              xml_node << element(old_content_type, nil, old_content_str)
            when key == :description then xml_node << element(key.to_s, nil, val)
            else xml_node[key] = val
          end
        end
        xml_node[:date] = Time.now.to_s
      end
      super xml_node
    end

    def description
      descr = find_child(:description)
      descr.nil? ? nil : descr.content
    end

    def date
      self[:date]
    end

    def affected_parent
      resolve_ref self[:parent]
    end

    def base_template
      root
    end

    def target
      children.each do |child| return child unless child.type == :description end
    end
  end

  class Remove < Change
    def description
      super || %(Component '#{removed.id}' of type '#{removed.type}' was removed from component '#{affected_parent.id}' of type '#{affected_parent.type}'.)
    end

    alias_method :removed, :target
  end

  class Insert < Change
    def description
      super || %(Component '#{inserted.id}' of type '#{inserted.type}' was added to component '#{affected_parent.id}' of type '#{affected_parent.type}'.)
    end

    def inserted
      resolve_ref self[:target]
    end
  end

  class Edit < Change
    def description
      return super if super
      descr = %(Component '#{affected_parent.id}' of type '#{affected_parent.type}' )
      is_attribute = target.type != 'content'
      oc = old_content
      is_new = old_content.empty?
      descr << case
        when is_new && is_attribute then "given new attribute '#{target.type}' with value '#{new_content}'."
        when is_new && !is_attribute then "given new #{target.type} '#{new_content}'."
        when !is_new && is_attribute then "changed attribute '#{target.type}' value from '#{old_content}' to '#{new_content}'."
        when !is_new && !is_attribute then "changed #{target.type} from '#{old_content}' to '#{new_content}'."
        else 'edited.'
      end
      descr
    end

    def old_content
      target.type == 'nil' ? '' : target.content
    end

    def new_content
      affected_parent.content
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
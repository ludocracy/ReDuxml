require_relative '../patterns/grammar'

module Patterns
  include Components

  class History < Component
    include Enumerable

    attr_reader :rules

    def initialize xml_node=nil, args={}
      xml_node = %(<history><insert id="change_0" owner="system"><description>file created</description><date>#{Time.now.to_s}</date></insert></history>) if xml_node.nil?
      super xml_node, reserved: %w(insert remove change_content change_attribute new_content new_attribute error correction instantiate move undo)
    end

    def update type, change_hash
      change_class = Patterns::const_get type.to_s.classify
      change_comp = change_class.new(nil, change_hash)
      add change_comp, 0
      @xml_root_node.prepend_child change_comp.xml
      unless change_comp.type[-5..-1] == 'error' || root.grammar.nil?
        root.grammar.qualify change_comp
      end
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

  class Change < Pattern
    def class_to_xml args={}
      xml_node = super args
      xml_node[:date] = Time.now.to_s
      xml_node
    end

    def description
      descr = find_child(:description)
      descr.nil? ? nil : descr.content
    end

    def date
      self[:date]
    end

    def subject context_template=root
      resolve_ref :subject, context_template
    end

    def base_template
      root
    end
  end

  class Remove < Change
    def class_to_xml args={}
      super(args) << args[:object].xml
    end

    def description
      super ||
          %(Component '#{removed.id}' of type '#{removed.type}' was removed from component '#{subject.id}' of type '#{subject.type}'.)
    end

    def removed
      object
    end
  end

  class Insert < Change
    def description
      super || %(Component '#{inserted.id}' of type '#{inserted.type}' was added to component '#{subject.id}' of type '#{subject.type}'.)
    end

    def inserted
      resolve_ref :object, root
    end
  end

  class Edit < Change
    def description
      super if super
    end
  end

  class ChangeContent < Edit
    def class_to_xml args={}
      xml_node = super
      xml_node.content = args[:object].to_s
      xml_node
    end

    def description
      super
      "Component '#{subject.id}' of type '#{subject.type}' changed content from '#{old_content}' to '#{new_content}'."
    end

    def old_content
      content
    end

    def new_content
      subject.content
    end
  end

  class ChangeAttribute < Edit
    def class_to_xml args={}
      xml_node = super args
      args[:object].each do |k, v| xml_node[k] = v end if args[:object].is_a?(Hash)
      xml_node
    end

    def description
      super
      "Component '#{subject.id}' of type '#{subject.type}' changed attribute '#{self[:attr_name]}' value from '#{self[:old_value]}' to '#{self[:new_value]}'."
    end
  end

  class NewContent < Edit
    def description
      super
      "Component '#{subject.id}' of type '#{subject.type}' given new content '#{new_content}'."
    end

    def new_content
      subject.content
    end
  end

  class NewAttribute < Edit
    def class_to_xml args={}
      xml_node = super args
      args[:object].each do |k, v| xml_node[k] = v end if args[:object].is_a?(Hash)
      xml_node
    end

    def description
      super
      "Component '#{subject.id}' of type '#{subject.type}' given new attribute '#{self[:attr_name]}' with value '#{self[:new_value]}'."
    end
  end

  class Undo < Change
    def description
      super || "#{subject.id} undone."
    end

    def undone_change
      self[:change]
    end
  end

  class Error < Change
    def initialize xml_node, args={}
      super xml_node, args
    end

    def violated_rule
      root.rules[self[:rule]]
    end
  end

  class ValidateError < Error
    def description
      super || "#{non_compliant_change.description} which violates rule: #{violated_rule.description}."
    end

    def non_compliant_change
      root.history.find_child self[:object]
    end
  end

  class QualifyError < Error
    def description
      super || "#{non_compliant_pattern.description} which violates rule: #{violated_rule.description}."
    end

    def non_compliant_object
      object
    end
  end
end # end of module Patterns
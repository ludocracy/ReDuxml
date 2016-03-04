require_relative 'component/component'

module Patterns
  include Components
  class Pattern < Component
    include Comparable

    def initialize comp, args = {}
      if comp.respond_to?(:is_component?)
        xml_node = class_to_xml args
        xml_node[:subject] = comp.id
      else
        xml_node = comp
      end
      super xml_node, args
    end

    def class_to_xml args={}
      xml_node = super()
      args.each do |k, v| xml_node[k] = v.respond_to?(:id) ? v.id : v end
      xml_node
    end

    def description
      super ||
          %(Component '#{subject.id}' of type '#{subject.type}' affects '#{object.id}' of type '#{object.type}'.)
    end

    def subject context_template
      resolve_ref :subject, context_template
    end

    def object
      has_children? ? children.first : resolve_ref(:object, root)
    end

    def <=> pattern
      return 1 unless pattern.respond_to?(:subject)
      case subject <=> pattern.subject
        when -1 then -1
        when 0 then object <=> pattern.object
        else -1
      end
    end
  end # class Pattern

  class Grammar < Component
    @rdb
    def initialize xml_node, args={}
      super xml_node, reserved: %w{rule}
    end

    def [] rule_id
      find_child rule_id
    end

    def validate comp
      qualify Pattern.new comp
    end

    def qualify change
      children.each do |child|
        subj = change.subject root
        if subj && child[:subject] == subj.type
          child.qualify change
        end
      end
    end
  end # class Grammar

  class Rule < Pattern
    def class_to_xml args={}
      xml_node = super
      xml_node[:subject] = args[:subject].to_s
      xml_node << args[:statement]
      xml_node.remove_attribute 'statement'
      xml_node
    end

    def qualify change
      subject = change.subject root
      begin
        q = eval content, get_binding(subject)
      rescue NoMethodError
        q ||= true
      end
      type = (change.type == 'pattern' ? :validate_error : :qualify_error)
      report type, subject unless q
    end

    def get_binding subject
      binding
    end
  end
end
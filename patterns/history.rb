require_relative 'component/component'
module Patterns
  include Components

  class History < Component
    def initialize xml_node, args={}
      super xml_node, reserved: %w(insert remove edit error correction instantiate move undo)
    end

    # a special register function is used by the History, instead of the usual add child to avoid adding a history of the history to the history
    def register change, owner
      current_change = change
      while current_change do
        current_change[:owner] = owner
        # adding to head so latest changes are on top
        @xml_cursor.children.first.add_previous_sibling
        @children.add_child current_change
        current_change.next!
      end
    end

    def generate_descr

    end

    def register_with_owner change
      register change, @parent.owners
    end

    def last_change
      @children.last
    end

    def size
      @children.size
    end

    def change_hash
      @children_hash
    end

    def get_changes
      # handle cases for searches by: date, date range, owner, type, target,
    end

    private :register
  end

  # individual change; not to be used, only for subclassing
  class Change < Component
    def initialize xml_node, args = {}
      super xml_node
    end

    def description
      find_child :description
    end

    def date
      find_child :date
    end

    def generate_new_xml args
      super
      @previous = args[:previous]
      @next = nil
      @xml_cursor['previous'] = @previous.id unless @previous.nil?
      @ref = args[:ref]
      @xml_cursor['ref'] = @ref.id unless @ref.nil?
      @timestamp = Time.now
      @xml_cursor << Nokogiri::XML::Node.new('date', @xml_doc)
      @xml_cursor << @timestamp.to_s
      # description will be generated or input later and only when triggered
      @xml_cursor << Nokogiri::XML::Node.new('description', @xml_doc)
    end

    def generate_descr
      @description = " at #{@timestamp}."
    end

    def push component
      if component.is_a? Change
        @next = component
        component.previous = self
        component
      else
        super component
      end
    end

    def previous= ref
      @previous ||= ref
    end

    private :generate_descr

    attr_reader :next, :ref, :timestamp, :description
  end

  # Component instantiated; holds pointers to Edits to parameter values if redefined for this instance
  # holds pointer to antecedent; generates fresh ID for instance; adds as new child to template
  class Instantiate < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  # error found during build inspection process (syntax errors) or during general inspection - saved to file if uncorrected on commit
  # points to rule violated and/or syntax marker and previous error in exception stack
  class Error < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  # build-time, inspection or committed error correction - points to error object
  # also points to change object that precipitated this one
  # (could be another correction or other change-type other than Error or Instantiate)
  class Correction < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  # removal of node can occur when building design from de-instantiation (@if == false)
  # when inspecting from a given perspective, or from user input when editing
  class Remove < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  # insertion of node can occur when building design from instantiation
  # after inspector reports changes (when historian inserts changes into history)
  # and from user input when editing
  # the initialization strings really should be loaded from the RelaxNG. LATER!!!
  class Insert < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    # because owner is not known until insert is registered with history, this method is kept private
    def generate_descr
      self[:description] = "#{self[:owner].to_s} added #{@ref.name} (#{@ref.id}) to #{@ref.parent.name} (#{@ref.id})" + self[:description]
    end

    private :generate_descr
  end

  class Move < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

  # change to element content or attribute value, essentially the actual content of the Component has changed
  # this can occur from owner input when editing
  # or initiated by Builder when dealing with parameters (and nothing else)
  class Edit < Change
    # string containing new content
    @new_content
    # string containing old content (if content is XML, string can be converted to XML)
    @old_content
    # xpath to changed element
    @xpath
    # string if empty content change was to element; if non-empty is name of attribute value changed
    @attributeOrNo
    @previous
    @next


    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml

    end
  end

  class Undo < Change
    def initialize xml_node, args = {}
      super xml_node, args
    end

    def generate_new_xml
    end
  end

end # end of module Patterns
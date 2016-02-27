require_relative '../patterns/design'

module Patterns
  class Directives < Design
    def initialize xml_node

    end
    # leave room here for other types of directives
    def ref
      self[:ref]
    end

    def doc_objects
      self[:doc_objects]
    end

    def diff
      self[:diff]
    end

    def views
      self[:views].split(' ')
    end

    def options
      # return all children named '*_option'
    end
  end

  class Merge < Instantiate
    def initialize ref, diff, doc_obj

    end

    def ref
      super.split(' ')
    end

    def to_doc
      doc_obj_class = const_get doc_obj.to_s.capitalize
      doc_obj_class.merge
    end
  end

  class Split < Instantiate
    def initialize ref, diff, doc_obj

    end
  end

  class Instantiate < Instance
    def instantiate

    end
  end


  class RegisterDef < Component

  end

  class BitField < Component

  end

  class ResetValue < Component
    include Addressable
  end

  class Address < Component
    include Addressable
  end

  class BitValue < Component
    include Addressable
  end
end
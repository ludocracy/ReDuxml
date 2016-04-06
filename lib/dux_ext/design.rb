require File.expand_path(File.dirname(__FILE__) + '/parameters')

module Dux
  # Instances are copies of another XML element with a distinct set of parameter values
  # like Objects in relation to a Class
  class Instance < Object
    # returns parameters or empty array
    def params
      p = find_child 'parameters'
      p.simple_class == 'parameters' ? p : []
    end

    # creates copy of referent (found from context given by 'meta') at this element's location
    def instantiate(meta=nil)
      new_kids = []
      target = resolve_ref :ref, meta
      if target.nil?
        children.each do |child|
          new_kids << child if child.simple_class != 'parameters'
        end
      else
        new_kid = target.clone
        new_kid.rename "#{id}.#{target.id}"
        new_kids << new_kid
      end
      new_kids
    end # def instantiate
  end # class Instance

  # root element for an XML file that is entirely parameterized
  class Design < Instance; end

  # links allow parameters to be bound to attribute values or element content in the design objects wrapped by the link
  class Link < Instance
    attr_reader :ref

    # TODO not sure how to represent this!
    def instantiate(target=nil)
      resolve_ref nil, target
      self
    end
  end

  # XML object array
  # represents a pattern of copies of a this object's children or referents
  # differentiates between copies using iterator Parameter
  class Array < Instance
    include Enumerable

    # reifies pattern by actually copying children and assigning each unique properties derived from iterator value
    # TODO do we need argument?
    def instantiate(meta=nil)
      size_expr = size.respond_to?(:to_i) ? size.to_i : size.to_s
      if size_expr.is_a? Fixnum
        iterator_index = 0
        new_children = []
        kids = []
        children.each do |kid| kids << kid.detached_subtree_copy end
        remove_all!
        size_expr.times do
          i = Instance.new
          i << Parameters.new(nil, iterator: iterator_index)
          kids.each do |kid| i << kid.detached_subtree_copy end
          i.rename name+iterator_index.to_s
          new_children << i
          iterator_index += 1
        end
        new_children
      else
        []
      end
    end # def instantiate

    # size can be Fixnum or a Parameter expression
    def size
      self[:size]
    end

    # overriding #each to only traverse children and return self on completion, not Enumerator
    def each &block
      @children.each &block
      self
    end
  end # class Array
end # module Dux
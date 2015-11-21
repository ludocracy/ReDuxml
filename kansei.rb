
#basic tree.rb structure, providing attributes: @name, @children, @children_hash, @siblings, @parent, @content etc.
require 'rubytree'

#descendant/ancestor of a design Component along the abstract/concrete dimension
#that is, all Components potentially have an abstract Kansei and concrete Kansei,
#and each Kansei in turn potentially has an abstract and/or concrete Kansei

#they are first divided as a hash; the keys are view or build configurations, the values are Arrays of Kansei
class Kansei_hash < Hash
  #can be initialized by array of key, value pair
  def initialize pair = []
    super[pair[0]] = Kansei_view.new pair[1]
  end

  def []= key, val
    super[key] = val if val.is_a? Kansei_array
  end
end

#each Kansei_array is actually two arrays joined head to head
#the zero index is the template Component itself,
#this index can differ depending on what is the current template, but can always returns to the template of record
class Kansei_array
  #reference component is the one actually created by the owner and not the OS
  @ref_component
  #Kansei representing more specified permutations of reference component
  @concretes = []
  #Kansei representing less specified permutations of reference component
  @abstracts = []

  def initialize component
    @this_component = component
  end

  #returns all Kansei children as single array assembled in this order:
  #abstract tail -> abstract head -> this_component -> concrete_head -> concrete tail
  #note index of reference template will get lost in this format!
  def get_kansei_array
    (@abstracts.reverse << @ref_component).concat @concretes
  end

  #defining push to select correct array; if given neither should be error
  def << component
    case component.class
      when 'Concrete'
        @concretes << component
      when 'Abstract'
        @abstracts << component
      else
        raise 'tried to add reference Component to Kansei_array! must be Concrete or Abstract'
    end
  end

  #defining [] to return Component from correct member
  def [] index
    case index
      #index is not actually an index - find matching element name
      when !(index.is_? 'Fixnum')
        get_kansei_array.select{|kansei| kansei.name == index}
      #index is negative - return from abstracts
      when index < 0
        #note that index must be subtracted because '0' is this Component
        @abstracts[index.abs - 1]
      #index is positive = return from concretes
      when index > 0
        @concretes[index - 1]
      #index is 0 - return the reference component
      when 0
        @ref_component
      else
        #this should never happen
    end
  end
end

#each Kansei is a Component representing a permutation of a reference template Component.
#They can be abstractions or concretions depending on whether the level of specificity,
#They can be views or builds depending on which axis
#b
class Kansei < Tree::TreeNode

end
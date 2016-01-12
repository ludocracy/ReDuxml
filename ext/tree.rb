require 'tree'
require_relative 'regexp'

# override rubytree to make name = element name and id = name (i.e. unique identifier)
module Tree
  class TreeNode
    attr_reader :name

    def id
      @id
    end

    protected :id

    def initialize content
      @name, @content = content.respond_to?(:name) ? content.name : content.match(Regexp.identifier), content
      @id = self.object_id

      self.set_as_root!
      @children_hash = Hash.new
      @children = []
    end

    # super is protected
    def set_as_root!              # :nodoc:
      self.parent = nil
    end

    # removing uniqueness test
    def add(child, at_index = -1)
      # Only handles the immediate child scenario
      raise ArgumentError,
            "Attempting to add a nil node" if child.nil?
      raise ArgumentError,
            "Attempting add node to itself" if self.equal?(child)
      raise ArgumentError,
            "Attempting add root as a child" if child.equal?(root)

      child.parent.remove! child if child.parent # Detach from the old parent

      if insertion_range.include?(at_index)
        @children.insert(at_index, child)
      else
        raise "Attempting to insert a child at a non-existent location"\
              " (#{at_index}) "\
              "when only positions from "\
              "#{insertion_range.min} to #{insertion_range.max} exist."
      end

      @children_hash[child.name] ||= Array.new
      @children_hash[child.name] << child
      child.parent = self
      child
    end
  end
end
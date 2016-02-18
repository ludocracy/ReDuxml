require 'tree'

# rubytree gem bug fix; submit to project once you get approval!
module Tree
  class TreeNode
    def each(&block)             # :yields: node

      return self.to_enum unless block_given?

      node_stack = [self]   # Start with this node

      until node_stack.empty?
        current = node_stack.shift    # Pop the top-most node
        if current                    # Might be 'nil' (esp. for binary trees)
          yield current               # and process it
          # Stack children of the current node at top of the stack
          # this line used to read: node_stack = current.children.concat(node_stack)
          # which had side effect of occasionally orphaning a child
          node_stack = node_stack.concat(current.children)
        end
      end

      return self if block_given?
    end
  end
end
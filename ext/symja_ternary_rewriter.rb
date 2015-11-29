module SymjaTernaryRewriter
# rewrite this and next method later to use Symja's visitors/patterns/replacement etc
  def second_rewrite_ternary_ast_to_if expr
    if expr.respond_to?(:isAST) && expr.isAST || expr.include?('->')
      ast = evalengine.parse expr
      colon_ast_vector = get_colon_ast_vector(ast).to_a
      # creating clones of orphans
      left_child = get_node(ast, colon_ast_vector+[1])
      right_child = get_node(ast, colon_ast_vector+[2])
      orphan_array = [get_node(ast, colon_ast_vector+[1]), get_node(ast, colon_ast_vector+[2])]
      # removing colon ast
      ternary_ast_vector = colon_ast_vector[0..-2]
      ast = get_node(ast, ternary_ast_vector).removeAtClone(colon_ast_vector.last)

      # finding grandparent that can take an orphan
      until ternary_ast_vector.empty? do
        ternary_ast = get_node(ast, ternary_ast_vector)
        ast = ternary_ast.addAtClone(TERNARY_ARITY, orphan_array.shift) if ternary_ast.size == TERNARY_ARITY
        ast = ternary_ast.setAtClone(0, operators[:if])
        ternary_ast_vector.pop
        break if orphan_array.empty?
      end
      second_rewrite_ternary_ast_to_if ast
    else
      expr
    end # end of if/else expr has/is part of ternary expression
  end


  private
  def get_colon_ast_vector(ast, colon_ast_vector=[])
    a=ast.to_a
    ast.to_a.each_with_index do |node, index|
      next if index.zero?
      n = node.toString
      h = node.head.toString
      case
        when !node.isAST
          next
        when node.head.toString == 'RuleDelayed'
          return colon_ast_vector+[index]
        when node.head.toString == 'Rule'
          colon_ast_vector = get_colon_ast_vector(node, colon_ast_vector+[index])
        else
      end
    end
    raise Exception if colon_ast_vector.empty?
    colon_ast_vector
  end

  def get_node(ast, index_vector)
    a = ast.to_a
    return ast.getPart(index_vector.first) if index_vector.size == 1
    sub_ast = ast.getPart(index_vector.first)
    sub_vector = index_vector[0..-2]
    get_node(sub_ast, sub_vector)
  end
end

module SymjaTernaryRewriters
  # needed because Symja already has uses for '?' and ':'
  # using roughly equivalent precedence operators instead
  def rewrite_ternary_to_placeholder_0 expr
    expr.gsub(/(\?|:)/,{'?' => '->', ':' => ':>'})
  end

  # symja doesn't understand solitary vars as boolean values
  def rewrite_ternary_vars_1 expr
    if expr.include?('->')
      expr.gsub(/\b[a-zA-Z][a-zA-Z0-9_]*\b(?=(?:\s*->))/) do |match|
        if match.match(/(true|false)/)
          match
        else
          "#{match}==true"
        end
      end
    else
      expr
    end
  end # end of def rewrite_ternary_vars_1

  def rewrite_ternary_to_ast_2 expr
    expr.match(/(->|:>)/) ? evalengine.parse(expr) : expr
  end

  # rewrite this and next method later to use Symja's visitors/lib/replacement etc
  def rewrite_ternary_ast_to_if_3 expr
    if expr.respond_to?(:isAST) && expr.isAST
      build_ternary_ast_stack expr
      # parse expression as Rule/RuleDelayed statement then find first RuleDelayed AST i.e. ternary ':'

      colon_ast = ternary_ast_stack.pop

      left_child = colon_ast.getPart(1)
      right_child = colon_ast.getPart(2)

      if left_child.toString == 'True' && right_child.toString == 'False'
        var = ternary_ast_stack.pop.getPart(1)
        return var if ternary_ast_stack.empty?
        ternary_ast_stack << ternary_ast_stack.pop.setAtClone(1, var)
      end

      ternary_ast_stack << ternary_ast_stack.pop.appendClone(left_child)

      orphan_stack = [right_child]
      ternary_ast_stack.reverse.each do |ternary_ast|
        if ternary_ast.size <= TERNARY_ARITY
          orphan_stack << ternary_ast.appendClone(orphan_stack.pop).setAtClone(0, operators[:if])
        else
          orphan_stack << ternary_ast
        end
        ternary_ast_stack.delete ternary_ast

        if ternary_ast_stack.empty?
          ternary_ast_stack << orphan_stack.pop
          until orphan_stack.empty?
            ternary_ast_stack << ternary_ast_stack.pop.appendClone(orphan_stack.pop)
          end
          break
        end
      end

      final_ast = ternary_ast_stack.pop

      # FUBAR *** can probably cut this out since the stack should only ever have one ast by now
      if final_ast.toString.match(/(->|:>)/)
        rewrite_ternary_ast_to_if_3 final_ast
      else
        final_ast.toString
      end
    else
      expr
    end # end of if expr is an AST in need of processing or not

  end # def rewrite_ternary_ast_to_if_3

  private
  def build_ternary_ast_stack ast
    operation = ast.head.toString
    if operation == 'RuleDelayed'
      ternary_ast_stack << ast
      true
    elsif operation.match(/(Rule|If)/)
      ast.to_a.each_with_index do |node, index|
        if node.isAST && build_ternary_ast_stack(node)
          ternary_stump = ast.copyUntil(index)
          if ternary_ast_stack.any? do |match| match.toString!=ternary_stump.toString end
            ternary_ast_stack.insert(0, ternary_stump)
          end
        end
      end
      true
    else
      false
    end
  end # def get_ternary_ast_stack

end # module SymjaTernaryRewriter

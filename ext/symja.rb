require File.expand_path(File.dirname(__FILE__) + '/symja_ternary_rewriter.rb')
begin # don't touch this load order!!!
  require 'java'
  require 'C:\Users\b33791\RubymineProjects\DesignOS\java\symja_android_library\bin\symja_android_library.jar'
  require 'C:\Users\b33791\RubymineProjects\DesignOS\java\symja_android_library\lib\COMMONS_MATH4_SYMJA.jar'

  java_import org.matheclipse.core.eval.EvalEngine
  java_import org.matheclipse.core.eval.ExprEvaluator
  java_import org.matheclipse.core.interfaces.IExpr
  java_import org.matheclipse.parser.client.SyntaxError # watch out for this! it's overriding ruby's SyntaxError
  java_import org.matheclipse.parser.client.math.MathException
  java_import org.matheclipse.parser.client.operator.ASTNodeFactory
end # loading java libraries - do not change order!!!

TERNARY_ARITY = 3

class Symja
  def evaluate expr
    postwrite evalengine.evaluate prewrite expr
  end

  private

  attr_reader :evalengine, :prewriter, :postwriter

  def initialize
    @evalengine = EvalEngine.new
    @prewriter = Pre_Rewriters.new(evalengine)
    @postwriter = Post_Rewriters.new(evalengine)
  end

  def prewrite expr
    rewrite expr, prewriter
  end

  def postwrite expr
    rewrite expr, postwriter
  end

  def rewrite expr, klass
    s = expr
    rewriters = klass.methods.keep_if do |w| w.to_s.include?('rewrite_') end
    rewriters.sort.each do |sym|
      s = s.to_s
      s = klass.method(sym).call(s)
    end
    s
  end # end of def rewrite

end # end of class Symja

class Rewriters
  private

  attr_reader :evalengine, :operators

  def initialize evalengine
    @evalengine = evalengine
    @operators = Hash(ternary:  f(:Rule), colon: f(:RuleDelayed), if: f(:If))
  end

  def f sym
    evalengine.parse(sym.to_s)
  end
end

class Pre_Rewriters < Rewriters
include SymjaTernaryRewriter # needed because Symja already has uses for '?' and ':'
  # using roughly equivalent precedence operators instead
  def first_rewrite_ternary_to_placeholder expr
    expr.gsub(/(\?|:)/,{'?' => '->', ':' => ':>'})
  end


  # end of rewrite_ternary_ast_to_if

end # end of class Pre_Rewriters

class Post_Rewriters < Rewriters

  # this is potentially dangerous; change to Pre_Rewriter and use pre-eval, post-parse AST manipulation
  def first_rewrite_negate_both_sides expr
    if expr.include?('==(!') then expr.gsub('==(!','!=!(!')
    elsif expr.include?('!=(!') then evalengine.evaluate(expr.gsub('!=(!', '==!(!'))
    else expr end
  end

  # this can stay in Ruby as it's cheap to do here
  def second_rewrite_lower_case_booleans expr
    expr.gsub(/(True|False)/,{'True' => 'true', 'False' => 'false'})
  end

  def third_rewrite_to_str expr
      expr.to_s
  end
end # end of class Post_Rewriters

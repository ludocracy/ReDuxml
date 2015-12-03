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
    puts "Evaluating '#{expr}'"
    prepped_expr = prewrite expr
    ans = evalengine.evaluate prepped_expr
    postwrite(ans.toString=='Null' ? prepped_expr : ans)
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
    rewriters.sort do |a,b| a.to_s[-1]<=>b.to_s[-1] end.each do |sym|
      s = klass.method(sym).call(s)
    end
    s
  end # end of def rewrite

end # end of class Symja

class Rewriters
  private

  attr_reader :evalengine, :operators
  attr_accessor :ternary_ast_stack

  def initialize evalengine
    # holds stack of operations involving ternary operators; only final element may be for colon
    @ternary_ast_stack = []
    @evalengine = evalengine
    @operators = Hash(ternary:  f(:Rule), colon: f(:RuleDelayed), if: f(:If))
  end

  def f sym
    evalengine.parse(sym.to_s)
  end
end

class Pre_Rewriters < Rewriters
  # pulled out ternary rewriter because it's complicated
  include SymjaTernaryRewriters
end # end of class Pre_Rewriters

class Post_Rewriters < Rewriters
  def rewrite_ast_str_0 ast
    ast.to_s
  end

  # this is potentially dangerous; change to Pre_Rewriter and use pre-eval, post-parse AST manipulation
  def rewrite_negate_both_sides_1 expr
    if expr.include?('==(!') then expr.gsub('==(!','!=!(!')
    elsif expr.include?('!=(!') then evalengine.evaluate(expr.gsub('!=(!', '==!(!')).to_s
    else expr end
  end

  def rewrite_boolean_identities_2 expr
    expr.gsub(/\b[a-zA-Z][a-zA-Z0-9_]*\b\s*(==)\s*True/) do |match| match[/\b[a-zA-Z][a-zA-Z0-9_]*\b/] end
    .gsub(/\b[a-zA-Z][a-zA-Z0-9_]*\b\s*(==)\s*False/) do |match| "!#{match[/\b[a-zA-Z][a-zA-Z0-9_]*\b/]}" end
    .gsub(/\b[a-zA-Z][a-zA-Z0-9_]*\b\s*(!=)\s*True/) do |match| "!#{match[/\b[a-zA-Z][a-zA-Z0-9_]*\b/]}" end
    .gsub(/\b[a-zA-Z][a-zA-Z0-9_]*\b\s*(!=)\s*False/) do |match| match[/\b[a-zA-Z][a-zA-Z0-9_]*\b/] end
  end

  # this can stay in Ruby as it's cheap to do here
  def rewrite_lower_case_booleans_3 expr
    expr.gsub(/(True|False)/,{'True' => 'true', 'False' => 'false'})
  end
end # end of class Post_Rewriters

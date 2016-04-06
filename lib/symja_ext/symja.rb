require File.expand_path(File.dirname(__FILE__) + '/symja_ternary_rewriter.rb')
require File.expand_path(File.dirname(__FILE__) + '/../ruby_ext/string.rb')
require 'singleton'
begin # don't touch this load order!!!
  require 'java'
  require File.expand_path(File.dirname(__FILE__) + '/../../java/symja_android_library/bin/symja_android_library.jar')
  require File.expand_path(File.dirname(__FILE__) + '/../../java/symja_android_library/bin/symja_android_library.jar')
  require File.expand_path(File.dirname(__FILE__) + '/../../java/symja_android_library/lib/COMMONS_MATH4_SYMJA.jar')

  java_import org.matheclipse.core.eval.EvalEngine
  java_import org.matheclipse.core.eval.ExprEvaluator
  java_import org.matheclipse.core.interfaces.IExpr
  java_import org.matheclipse.parser.client.SyntaxError # watch out for this! it's overriding ruby's SyntaxError
  java_import org.matheclipse.parser.client.math.MathException
  java_import org.matheclipse.parser.client.operator.ASTNodeFactory
end # loading java libraries - do not change order!!!

# number of arguments required by 'ternary' or 'if' operation
TERNARY_ARITY = 3

# Ruby container for Symja (Symbolic Java) symbolic algebra evaluator
class Symja
  # TODO is this necessary?
  include Singleton

  # overriding evaluate to take in Dux::Parameter expressions and evaluate them
  def evaluate(expr, parameter_hash={})
    result_expr = expr.clone
    string_expr_or_false = substitute! result_expr, parameter_hash
    unless string_expr_or_false
      prepped_expr = prewrite result_expr
      ans = evalengine.evaluate prepped_expr
      result_expr = postwrite(ans.toString=='Null' ? prepped_expr : ans)
    end
    result_expr
  end # def evaluate

  private

  attr_reader :evalengine, :prewriter, :postwriter

  # initializes rewriters and evaluation engine
  def initialize
    @evalengine = EvalEngine.new
    @prewriter = Pre_Rewriters.new evalengine
    @postwriter = Post_Rewriters.new evalengine
  end

  # replaces parameters in 'expr' with known values and returns resulting string
  def substitute!(expr, parameter_hash)
    result = nil
    string_expr_or_false = false
    expr.gsub!(Regexp.identifier) do |identifier|
      if parameter_hash[identifier.to_sym]
        result = parameter_hash[identifier.to_sym]
        if result.is_a?(Hash)
          result = result[:string]
          string_expr_or_false = true
        else
          string_expr_or_false = true if result.parameterized?
        end
      end
      result || identifier
    end
    string_expr_or_false
  end # def substitute!

  # apply pre-evaluation rewriters
  def prewrite(expr)
    rewrite expr, prewriter
  end

  # apply post-evaluation rewriters
  def postwrite(expr)
    rewrite expr, postwriter
  end

  # take given Rewriter 'klass' and apply its methods to 'expr'
  def rewrite(expr, klass)
    s = expr
    rewriters = klass.methods.keep_if do |w| w.to_s.include?('rewrite_') end
    rewriters.sort do |a,b| a.to_s[-1]<=>b.to_s[-1] end.each do |sym|
      s = klass.method(sym).call(s)
    end
    s
  end # end of def rewrite
end # end of class Symja

# container class for rewriting methods
class Rewriters
  private

  attr_reader :evalengine, :operators
  attr_accessor :ternary_ast_stack

  # initializes rewriters, especially for ternary operation rewriter
  def initialize(evalengine)
    # holds stack of operations involving ternary operators; only final element may be for colon
    @ternary_ast_stack = []
    @evalengine = evalengine
    @operators = Hash(ternary:  f(:Rule), colon: f(:RuleDelayed), if: f(:If))
  end

  # converts given symbol into corresponding operator
  def f(sym)
    evalengine.parse(sym.to_s)
  end
end # class Rewriters

# rewriters that must run before evaluating expression
class Pre_Rewriters < Rewriters
  # pulled out ternary rewriter because it's complicated
  include SymjaTernaryRewriters
end # end of class Pre_Rewriters

# rewriters that clean up output from evaluation of expression
# note that methods run in order of integer at end of method name
# TODO make each rewriter an object with priority rating to order methods!!!
class Post_Rewriters < Rewriters
  # converts AST to string in preparation for next method
  def rewrite_ast_str_0(ast)
    ast.to_s
  end

  # negating both sides of a boolean statement can remove extraneous negations
  # this is potentially dangerous; change to Pre_Rewriter and use pre-eval, post-parse AST manipulation
  def rewrite_negate_both_sides_1(expr)
    if expr.include?('==(!') then expr.gsub('==(!','!=!(!')
    elsif expr.include?('!=(!') then evalengine.evaluate(expr.gsub('!=(!', '==!(!')).to_s
    else expr end
  end

  # simplifies Boolean identities e.g. true && param => param
  def rewrite_boolean_identities_2(expr)
    expr.gsub(/\b[a-zA-Z][a-zA-Z0-9_]*\b\s*(==)\s*True/) do |match| match[/\b[a-zA-Z][a-zA-Z0-9_]*\b/] end
    .gsub(/\b[a-zA-Z][a-zA-Z0-9_]*\b\s*(==)\s*False/) do |match| "!#{match[/\b[a-zA-Z][a-zA-Z0-9_]*\b/]}" end
    .gsub(/\b[a-zA-Z][a-zA-Z0-9_]*\b\s*(!=)\s*True/) do |match| "!#{match[/\b[a-zA-Z][a-zA-Z0-9_]*\b/]}" end
    .gsub(/\b[a-zA-Z][a-zA-Z0-9_]*\b\s*(!=)\s*False/) do |match| match[/\b[a-zA-Z][a-zA-Z0-9_]*\b/] end
  end

  # convert Java-style Booleans (capitalized) to Ruby (lower case)
  # this can stay in Ruby as it's cheap to do here
  def rewrite_lower_case_booleans_3(expr)
    expr.gsub(/(True|False)/,{'True' => 'true', 'False' => 'false'})
  end
end # end of class Post_Rewriters

begin # don't touch this load order!!!
  require_relative 'component'
  require 'java'
  require 'C:\Users\b33791\RubymineProjects\DesignOS\java\symja_android_library\bin\symja_android_library.jar'
  require 'C:\Users\b33791\RubymineProjects\DesignOS\java\symja_android_library\lib\COMMONS_MATH4_SYMJA.jar'

  java_import org.matheclipse.core.eval.EvalEngine
  java_import org.matheclipse.core.eval.ExprEvaluator
  java_import org.matheclipse.core.interfaces.IExpr
  java_import org.matheclipse.parser.client.SyntaxError
  java_import org.matheclipse.parser.client.math.MathException
end # loading java libraries - do not change order!!!

module Symja
  def evaluate
    postwrite EvalEngine.new.evaluate prewrite self
  end

  # refactor this to use symja's builtin rewriters!!! others (e.g. var == !var bug) require AST manipulation
  def prewrite macro_string_expr
    case
      when macro_string_expr.include?('any banned operators') then raise LogicException
      when macro_string_expr.include?('?')
      when macro_string_expr.include?('functions')
      when macro_string_expr.include?('comparisons? then check for negation bug')
    end
  end


  def postwrite result_expr # refactor this to use symja's builtin rewriters!!!
    # reconstitute decomposed expressions
    # lowercase booleans?
    #
  end

  private :postwrite, :prewrite
end
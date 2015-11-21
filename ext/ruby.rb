require 'java'
require 'C:\Users\b33791\RubymineProjects\DesignOS\java\symja_android_library\bin\symja_android_library.jar'
require 'C:\Users\b33791\RubymineProjects\DesignOS\java\symja_android_library\lib\COMMONS_MATH4_SYMJA.jar'

java_import org.matheclipse.core.eval.EvalEngine
java_import org.matheclipse.core.eval.ExprEvaluator
java_import org.matheclipse.core.interfaces.IExpr
java_import org.matheclipse.parser.client.SyntaxError
java_import org.matheclipse.parser.client.math.MathException

class String
  def prewrite macro_string_expr
    case
      when macro_string_expr.include?('any banned operators') then raise LogicException
      when macro_string_expr.include?('?')
      when macro_string_expr.include?('functions')
      when macro_string_expr.include?('comparisons? then check for negation bug')
    end
  end
  
  def evaluate
    EvalEngine.new.evaluate(prewrite(self)).to_s.postwrite
  end

  def postwrite
    # reconstitute decomposed expressions
    # lowercase booleans?
    #
  end

  private :postwrite, :prewrite
end

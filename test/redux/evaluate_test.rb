require_relative '../../lib/re_dux/evaluate'
require 'test/unit'

class EvaluateTest < Test::Unit::TestCase
  include ReDuxml

  def setup
    @e = Evaluator.new
    @cases = {
        #boolean
        and_simple:             [true,          'true && true'],
        and_identity:           ['var',         'var && true'],
        and_cancel:             [false,         'var && false'],
        and_vars:               ['var',         'var && var'],
        and_vars_diff:          ['var0&&var1',  'var0 && var1'],
        or_simple:              [true,          'false || true'],
        or_identity:            ['var',         'var || false'],
        or_cancel:              [true,          'var || true'],
        or_vars:                ['var',         'var || var'],
        or_vars_diff:           ['var0||var1',  'var0 || var1'],
        not_simple:             [false,         '!true'],
        not_and:                [true,          '!(true && false)'],
        not_or:                 [false,         '!(true || false)'],
        not_cancel:             [true,          '!!true'],
        non_nested:             [true,          '!!!!!!!!!false'],
        not_var:                ['!var',        '!var'],
        ternary_simple:         [1,             'true ? 1 : 0'],
        ternary_combinate:      [0,             'false && true ? 1 : 0'],
        ternary_var_con:        ['var?1:0',     'var ? 1 : 0'],
        ternary_var_true:       ['var',         'true ? var : 0'],
        ternary_var_false:      ['var',         'false ? 1 : var'],
        ternary_var_var_false:  ['var?var:0',   'var ? var : 0'],
        ternary_var_true_var:   ['var?1:var',   'var ? 1 : var'],
        ternary_nest_con:       [1,             '(false ? true : false) ? 1 : 0'],
        ternary_nest_true:      [9,             'true ? true ? 9 : 1 : 0'],
        ternary_nest_false:     [9,             'false ? 0 : true ? 9 : 0'],

        #arithmetic
        add_simple:             [10,            '9 + 1'],
        add_identity:           [9,             '9 + 0'],
        add_var:                ['var+9',       '9 + var'],
        sub_simple:             [8,             '9 - 1'],
        sub_identity:           [9,             '9 - 0'],
        sub_var:                ['-var+9',      '9 - var'],
        sub_cancel:             [0,             'var - var'],
        mul_simple:             [6,             '2 * 3'],
        mul_identity:           ['var',         'var * 1'],
        mul_cancel:             [0,             'var * 0'],
        mul_var:                ['2*var',       '2 * var'],
        mul_vars:               ['var**2',      'var * var'],
        div_simple:             [2,             '8 / 4'],
        div_identity:           [8,             '8 / 1'],
        div_var:                ['0.5*var',     'var / 2'],
        div_cancel:             [1,             'var / var'],
        exp_simple:             [8,             '2**3'],
        exp_identity:           ['var',         'var**1'],
        exp_var:                ['2**var',      '2**var'],
        exp_cancel:             [1,             'var**0'],
        log_simple:             [3.0,           'log(8, 2)'],
        #log_var:                ['log(2,var)',  'log(2, var)'], TODO clean up return value string!
        mod_simple:             [2,             '8 % 6'],
        mod_var:                ['var%2',       'var%2'],
        neg_simple:             [-9,            '-9'],
        neg_identity:           [0,             '-0'],
        neg_var:                ['-var',        '-var'],
        add_div:                [12,            '9 + 9/3'],
        add_sub_var:            ['var',         '2*var - var'],
        mul_exp:                [24,            '3 * 2**3'],
        mul_exp_var:            ['var**5',      'var**2 * var**3'],
        div_expr_var:           ['var',         'var**3 / var**2'],

        #comparison
        eq_:                    [true,          '9 == 9'],
        eq_var:                 [true,          'var == var'],
        eq_var_diff:            ['var0==var1',  'var0 == var1'],
        eq_var_num:             ['var==9',      'var == 9'],
        eq_inverse:             ['var!=9',      '!(var == 9)'],
        ne_:                    [false,         '9 != 9'],
        ne_var:                 [false,         'var != var'],
        ne_var_num:             ['var!=0',      'var != 0'],
        ne_inverse:             ['var==9',      '!(var != 9)'],
        gt_:                    [true,          '9 > 0'],
        gt_var:                 [false,         'var > var'],
        gt_var_num:             ['var>0',       'var > 0'],
        gt_inverse:             ['var<=0',       '!(var > 0)'],
        gt_reverse:             ['var<0',        '-(var > 0)'],
        gte:                    [true,          '0 >= 0'],
        gte_var:                [true,          'var >= var'],
        gte_var_num:            ['var>=0',      'var >= 0'],
        gte_inverse:            ['var<0',       '!(var >= 0)'],
        gte_reverse:            ['var<=0',       '-(var >= 0)'],
        lt_:                     [true,          '0 < 9'],
        lt_var:                 [false,         'var < var'],
        lt_var_num:             ['var<0',       'var < 0'],
        lt_inverse:             ['var>=0',      '!(var < 0)'],
        lt_reverse:             ['var>0',       '-(var < 0)'],
        lte:                    [true,          '0 <= 0'],
        lte_var:                [true,          'var <= var'],
        lte_var_num:            ['var<=0',      'var <= 0'],
        lte_inverse:            ['var>0',      '!(var <= 0)'],
        lte_reverse:            ['var>=0',        '-(var <= 0)'],

        #string
        string_eq:              [true,          '"string" == "string"'],
        string_dbl_single:      [true,          "\"string\" == 'string'"],
        string_lt:              [true,          '"strin" < "string"'],
        string_gt:              [true,          '"string" > "strin"'],
        string_ne:              [false,         '"string" != "string"'],
        string_add:             ['"string"',    '"str" + "ing"'],
        string_range:           ['"trin"',      '"string"[1..-2]'],
        string_substr:          ['"trin"',      '"string"[1,4]'],
        string_eq_var:          ['var=="str"',  'var == "str"']
    }
  end

  attr_reader :cases, :e

  def test_substitution

  end

  def test_math
    cases.each do |key, ansque|
      if %w(neg add sub mul div exp mod).include?(key.to_s[0..2])
        result = e.evaluate(ansque.last)
        assert_equal(ansque.first, result, ansque.last)
      end
    end
  end

  def test_boolean
    omit
    cases.each do |key, ansque|
      if %w(and or_ not ter).include?(key.to_s[0..2])
        result = e.evaluate(ansque.last)
        assert_equal(ansque.first, result, ansque.last)
      end
    end
  end

  def test_string
    omit
    cases.each do |key, ansque|
      if %w(string).include?(key.to_s[0..2])
        result = e.evaluate(ansque.last)
        assert_equal(ansque.first, result, ansque.last)
      end
    end
  end

  def test_compare
    cases.each do |key, ansque|
      if %w(eq_ ne_ gt_ gte lt_ lte).include?(key.to_s[0..2])
        result = e.evaluate(ansque.last)
        assert_equal(ansque.first, result, "#{key}: '#{ansque.last}'")
      end
    end
  end
end
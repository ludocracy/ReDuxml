require File.expand_path(File.dirname(__FILE__) + '/../lib/re_duxml')
require 'test/unit'

class ReDuxmlTest < Test::Unit::TestCase
  # Called before every test method runs. Can be used
  # to set up fixture information.

  include ReDuxml

  def setup
  end

  # def test_load_from_string
  #   doc = Saxer.sax('<a><b if="@(i < 2)"/></a>')
  #
  #   partial_result = resolve(doc)
  #   assert_equal '<a><b if="@(i<2)"/></a>', partial_result.to_s
  #
  #     doc = Saxer.sax('<a><b if="@(i < 2)"/></a>')
  #   false_result = resolve(doc, {i: 5})
  #   assert_equal '<a/>', false_result.to_s
  #
  #     doc = Saxer.sax('<a><b if="@(i < 2)"/></a>')
  #   true_result = resolve(doc, {i: 1})
  #   assert_equal '<a><b/></a>', true_result.to_s
  # end
  #
  # def test_multiple_params
  #   doc = Saxer.sax('<a><b if="@(i < j)">i == @(i); j == @(j)</b></a>')
  #   partial_result = resolve(doc)
  #   assert_equal '<a><b if="@(i<j)">i == @(i); j == @(j)</b></a>', partial_result.to_s
  #
  #   doc = Saxer.sax('<a><b if="@(i < j)">i == @(i); j == @(j)</b></a>')
  #   full_result = resolve(doc, {i: 1, j: 2})
  #   assert_equal '<a><b>i == 1; j == 2</b></a>', full_result.to_s
  # end
  #
  # def test_if_resolution
  #   resolve File.expand_path(File.dirname(__FILE__) + '/../xml/conditionals.xml')
  #   answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/conditionals.xml')
  #   assert_equal answer.root.to_s, doc.root.to_s
  # end

  def test_inline_resolution
    # resolve File.expand_path(File.dirname(__FILE__) + '/../xml/inline_param.xml')
    # answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/inline_param.xml')
    # assert_equal answer.root.to_s, doc.root.to_s
    #
    # resolve File.expand_path(File.dirname(__FILE__) + '/../xml/inline_param.xml'), {other_param: 'String'}
    # answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/inline_param_unknown.xml')
    # assert_equal answer.root.to_s, doc.root.to_s

    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/inline_param.xml'), {other_param: '"Standard string"'}
    answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/inline_param_string.xml')
    assert_equal answer.root.to_s, doc.root.to_s
  end

  # def test_param_overrides
  #   resolve File.expand_path(File.dirname(__FILE__) + '/../xml/param_override.xml')
  #   answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/param_override.xml')
  #   assert_equal answer.root.to_s, doc.root.to_s
  # end
  #
  # def test_nonidentical_insts
  #   resolve File.expand_path(File.dirname(__FILE__) + '/../xml/fraternal_twins.xml')
  #   answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/fraternal_twins.xml')
  #   assert_equal answer.root.to_s, doc.root.to_s
  # end
  #
  # def test_derived_params
  #   # TODO #resolve_str not being applied to parameter defs!
  #   resolve File.expand_path(File.dirname(__FILE__) + '/../xml/derived_params.xml')
  #   answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/derived_params.xml')
  #   assert_equal answer.root.to_s, doc.root.to_s
  # end
  #
  # def test_instantiate_array
  #   resolve File.expand_path(File.dirname(__FILE__) + '/../xml/array_inst.xml')
  #   answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/array_inst.xml')
  #   assert_equal answer.root.to_s, doc.root.to_s
  # end

  def teardown
  end
end

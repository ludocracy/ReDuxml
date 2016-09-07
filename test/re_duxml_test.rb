require File.expand_path(File.dirname(__FILE__) + '/../lib/re_duxml')
require 'test/unit'

class ReDuxmlTest < Test::Unit::TestCase
  # Called before every test method runs. Can be used
  # to set up fixture information.

  include ReDuxml

  def setup
  end

  def test_mixed_file
    #resolve SAMPLE_FILE
    # TODO create answer file to compare
  end

  def test_if_resolution
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/conditionals.xml')
    answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/conditionals.xml')
    assert_equal answer.root.to_s, doc.root.to_s
  end

  def test_inline_resolution
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/inline_param.xml')
    answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/inline_param.xml')
    assert_equal answer.root.to_s, doc.root.to_s
  end

  def test_param_overrides
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/param_override.xml')
    answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/param_override.xml')
    assert_equal answer.root.to_s, doc.root.to_s
  end

  def test_nonidentical_insts
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/fraternal_twins.xml')
    answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/fraternal_twins.xml')
    assert_equal answer.root.to_s, doc.root.to_s
  end

  def test_derived_params
    # TODO #resolve_str not being applied to parameter defs!
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/derived_params.xml')
    answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/derived_params.xml')
    assert_equal answer.root.to_s, doc.root.to_s
  end

  def test_instantiate_array
    omit
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/array_inst.xml')
    answer = sax File.expand_path(File.dirname(__FILE__) + '/../xml/answers/array_inst.xml')
    assert_equal answer.root.to_s, doc.root.to_s
  end

  def teardown
  end
end
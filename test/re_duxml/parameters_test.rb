require File.expand_path(File.dirname(__FILE__) + '/../../lib/re_duxml/parameters')
require 'test/unit'

class ParametersTest < Test::Unit::TestCase

  def setup

  end

  def test_parameter_loading
    p = Parameters.new(nil, {instance_param_0: 'fff'})
    assert_equal 'fff', p[:instance_param_0]
  end

  def test_parameter_values_init
    h = {a: 'A', b: 'B'}
    p = Parameters.new(nil, h)
    assert_equal 'A', p[:a]
    assert_equal 'B', p[:b]
  end

  def test_parameter_string_value
    ans = 'string value'
    p = Parameter.new(nil, {name: :instance_param_0, value: ans})
    result = p[:value]
    assert_equal ans, result
  end

  def tear_down
  end
end

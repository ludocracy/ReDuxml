require_relative '../parameters'
require 'minitest/autorun'

class ParametersTest < MiniTest::Test
  include Patterns

  def setup

  end

  def test_parameter_loading
    p = Parameters.new(%(
            <parameters>
                <parameter name="instance_param_0" value="fff">
                    <description>what this param is about</description>
                </parameter>
            </parameters>
                   ))
    assert_equal 'fff', p['instance_param_0'].value
  end

  def test_parameter_values_init
    h = {a: 'A', b: 'B'}
    p = Parameters.new(%(
            <parameters>
                <parameter name="instance_param_0" value="fff">
                    <description>what this param is about</description>
                </parameter>
            </parameters>
                   ), h)
    assert_equal 'A', p[:a].value
    assert_equal 'B', p[:b].value
  end

  def test_parameter_values_post_init
    h = {a: 'A', b: 'B'}
    p = Parameters.new(%(
            <parameters>
                <parameter name="instance_param_0" value="fff">
                    <description>what this param is about</description>
                </parameter>
            </parameters>
                   ))
    p.update(h)
    assert_equal 'A', p[:a].value
    assert_equal 'B', p[:b].value
  end

  def tear_down
  end
end

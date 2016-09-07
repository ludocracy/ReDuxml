require File.expand_path(File.dirname(__FILE__) + '/../../lib/ruby_ext/string')
require 'test/unit'

class ParametersTest < Test::Unit::TestCase
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def balanced_parens
    assert true, '@(asdf)'.balanced_parens?
  end

  #
  def test_parameterized
    assert "asdf @(asd)".parameterized?
  end

  def test_not_parameterized
    assert !"asdf asd".parameterized?
  end
end
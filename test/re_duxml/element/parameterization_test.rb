require File.expand_path(File.dirname(__FILE__) + '/../../../lib/re_duxml/element/parameterization')
require 'test/unit'
require 'duxml'
include Duxml

class Element
  include Parameterization
end

class ParameterizationTest < Test::Unit::TestCase
  SAMPLE_TEMPLATE_FILE = File.expand_path(File.dirname(__FILE__) + '/../../../xml/sample_dux.xml')

  attr_reader :e
  def setup
  end

  def test_if
    f = sax(%(<birdhouse if="false">@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    t = sax(%(<birdhouse if="true">@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal false, f.if?
    assert_equal true, t.if?
  end

  def test_no_if
    t = sax(%(<birdhouse>@(pine)<color/><material><wood>pine</wood></material></birdhouse>))
    assert_equal true, t.if?
  end
end
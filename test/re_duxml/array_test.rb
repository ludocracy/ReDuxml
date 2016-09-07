require_relative '../../lib/re_duxml/array'
require 'test/unit'
include Duxml

class ArrayTest < Test::Unit::TestCase
  def setup
  end

  def teardown
    # Do nothing
  end

  def test_instantiate
    load File.expand_path(File.dirname(__FILE__) + '/../../xml/array.xml')
    b = doc.root[1]
    a = b.activate
    assert_equal %([<e/>, <e/>, <e/>, <e/>]), a.to_s
  end

  def test_instantiate_ref
    load File.expand_path(File.dirname(__FILE__) + '/../../xml/array_w_child.xml')
    answer = sax File.expand_path(File.dirname(__FILE__) + '/../../xml/answers/array_w_child.xml')
    a = doc.root.first.activate
    assert_equal answer.root.nodes.to_s, a.to_s
  end

  def test_instantiate_2d
    load File.expand_path(File.dirname(__FILE__) + '/../../xml/2d_array.xml')
    a = doc.root.first.activate
    assert_equal "[<duxml:array size=\"2\"><e/></duxml:array>, <duxml:array size=\"2\"><e/></duxml:array>, <duxml:array size=\"2\"><e/></duxml:array>, <duxml:array size=\"2\"><e/></duxml:array>]", a.to_s
  end
end
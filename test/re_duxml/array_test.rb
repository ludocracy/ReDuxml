require_relative '../../lib/re_duxml/array'
require 'test/unit'
include Duxml

class ArrayTest < Test::Unit::TestCase
  def setup
  end

  attr_accessor :d

  def teardown
    # Do nothing
  end

  def test_instantiate
    load File.expand_path(File.dirname(__FILE__) + '/../../xml/array.xml')
    a = doc.root.instantiate
    a0 = a.collect do |child| child.to_s end
    assert_equal %w(<e/> <e/> <e/> <e/> <e/>), a0
  end

  def test_instantiate_ref
    load File.expand_path(File.dirname(__FILE__) + '/../../xml/array_w_child.xml')
    a = doc.root.instantiate
    a0 = a.collect do |child| child.to_s end
    assert_equal %w(<e/> <e/> <e/> <e/>), a0
  end

  def test_instantiate_2d
    load File.expand_path(File.dirname(__FILE__) + '/../../xml/2d_array.xml')
    a = doc.root.instantiate
    a0 = a.collect do |child| child.to_s end
    assert_equal %w(<e/> <e/> <e/> <e/> <e/> <e/> <e/> <e/>), a0
  end

  def test_instantiate_array
    # TODO clean this up!
    resolve File.expand_path(File.dirname(__FILE__) + '/../xml/array_inst.xml')
    assert_equal '4 is an iterator expression', c.find_child('iterator_test.array_id3').content
  end
end
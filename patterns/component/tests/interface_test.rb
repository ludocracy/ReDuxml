require_relative '../component'
require 'minitest/autorun'
require 'nokogiri'
# tests term formatting - without regard to validity of evaluation
class InterfaceTest < MiniTest::Test
  include Components
  @e
  attr_reader :e
  def setup
    @e = Component.new(%(<birdhouse color="red" size="large"/>))
  end

  def test_to_s
    answer = %(<birdhouse color="red" size="large"/>)
    assert_equal answer, e.to_s
  end

  def test_promote_attr
    answer = %(<birdhouse size="large"><color>red</color></birdhouse>)
    e.promote(:color)
    assert_equal answer, e.to_s
  end

  def test_add_child
    answer = %(<birdhouse color="red" size="large"><material>pine</material></birdhouse>)
    e << Component.new(%(<material>pine</material>))
    assert_equal answer, e.to_s
  end

  def test_get_attr
    assert_equal 'large', e[:size]
  end
end

require_relative '../regexp'
require 'minitest/autorun'

# tests term formatting - without regard to validity of evaluation
class RegexpIdentifierTest < MiniTest::Test
  def setup

  end

  def test_regexp_identifier
    assert_equal "var", ("var ? true : false").match(Regexp.identifier)
  end

  def tear_down

  end

end # end of RewriterTest

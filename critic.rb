#tester takes queries, either from the Registry or user
#Registry queries include testing designs for changes and their validity upon commit, or generating analytics
module Tester
  require_relative "patterns"
  include Patterns
  #holds template for this tester - children include rules that apply to this session
  @tester_template

  def load_tester tester_template_file
    @tester_template = Template.new tester_template_file
  end

  def test open_template_file
    open_template_file
  end
end
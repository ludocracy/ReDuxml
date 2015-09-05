#Inspector takes queries, either from the Registry or user
#Registry queries include inspecting designs for changes and their validity upon commit, or generating analytics
module Inspector
  require_relative "Base_types"
  include Base_types
  #holds template for this inspector - children include rules that apply to this session
  @inspector_template

  def load_inspector inspector_template_file
    @inspector_template = Template.new inspector_template_file
  end

  #applies rules to given template and returns parts that qualify and errors for parts that don't
  def inspect open_template
    #traverse template
  end
end
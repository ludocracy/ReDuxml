require_relative "Base_types"
include Base_types
#main program - actually a template that has as subsystems
class DesignOS < Template
  #our customization of option parser to convert program arguments into options
  require_relative 'option_parser'
  require_relative 'Editor'
  require_relative 'Builder'
  require_relative 'Inspector'
  #Editor can be an XML editor or custom DesignOS interface but can also run in basic console mode (which underlies the other interfaces)
  include Editor
  #Builder constructs design from template, populating its children and applying parameter values
  include Builder
  #Inspector gets triggered by builder at certain points predetermined by OS and by user according to inputs
  include Inspector
  #the template that is called by the user
  alias_method :current_template, :doc

  def initialize *args
    #convert arguments into options
    options = Option_Parser.parse args
    super options.templates, options.user
    #load templates for each os module
    ['editor', 'builder', 'inspector'].each do |os_module|
      arg = @system.child(os_module)['ref']
      send ("load_#{os_module} #{arg}")
    end
    #start main loop
    main
  end

  #the main loop; default value is nil so process can listen for user input
  def main
    until Editor.exit?
      @current_template = inspect build edit @current_template
    end
  end
end

#BEGIN block
def BEGIN
  #set up user list access?
  #load GUI?
end

#main block
DesignOS.new

def END
  #save data?
  #update histories?
end
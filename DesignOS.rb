require_relative "Base_types"
include Base_types
#main program - actually a template that has as subsystems
class DesignOS < Template
  #our customization of option parser to convert program arguments into options
  require_relative 'option_parser'
  require_relative 'Editor'
  require_relative 'Builder'
  require_relative 'Inspector'

  #this is a fixed value
  OS_TEMPLATE_PATH = 'designos_template.xml'
  #Editor can be an XML editor or custom DesignOS interface but can also run in basic console mode (which underlies the other interfaces)
  include Editor
  #Builder constructs design from template, populating its children and applying parameter values
  include Builder
  #Inspector gets triggered by builder at certain points predetermined by OS and by user according to inputs
  include Inspector

  alias_method :current_template, :doc

  def initialize *args
    #convert arguments into options
    options = Option_Parser.parse args
    #setting global verbose mode; not sure if this is right!
    #$verbose = options.verbose
    super OS_TEMPLATE_PATH
    #splash text
    welcome
    #load templates for each os module
    ['editor', 'builder', 'inspector'].each do |os_module|
      puts "loading #{os_module}... ".chomp!
      arg = @system.child(os_module)['ref']
      if send ("load_#{os_module} #{arg}")
        puts "successfully loaded #{arg}."
      end
    end
    #start main loop
    main
  end

  #welcome text
  def welcome
    puts "DesignOS #{@version}"
  end

  #the main loop; default value is nil so process can listen for user input
  def main
    until Editor.exit?
      @current_template = inspect build edit @current_template
    end
  end

  private :welcome, :main
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
require_relative "Base_types"
include Base_types
#main program - actually a template that has as subsystems
class DesignOS < Template
  #our customization of option parser to convert program arguments into options
  require_relative 'option_parser'
  require_relative 'Editor'
  require_relative 'Builder'
  require_relative 'Tester'

  #this is a fixed value
  OS_TEMPLATE_PATH = 'designos_template.xml'
  #Editor can be an XML editor or custom DesignOS interface but can also run in basic console mode (which underlies the other interfaces)
  include Editor
  #Builder constructs design from template, populating its children and applying parameter values
  include Builder
  #Inspector gets triggered by builder at certain points predetermined by OS and by user according to inputs
  include Tester

  alias_method :current_template, :xml_node

  def initialize args
    #convert arguments into options
    options = Option_Parser.parse args
    #setting global verbose mode; not sure if this is right!
    #$verbose = options.verbose
    super OS_TEMPLATE_PATH
    #splash text
    welcome
    #load templates for each os module
    ['builder'].each do |os_module|
      @system.children.each do |child|
        STDERR.puts "#{__LINE__}: designOS @system=#{child.element}"
      end

      load_arg = @system.child(os_module)['ref']

      send("load_#{os_module}", load_arg)
    end
    if options.template
      @current_template = Template.new(options.template)
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
    #loop do
      @current_template = test build edit @current_template
      @current_template.save_template 'output.xml'
    #end
  end

  private :welcome, :main
end

#BEGIN block
def BEGIN
  #set up user list access?
  #load GUI?
end

#main block
DesignOS.new ARGV

def END
  #save data?
  #update histories?
end
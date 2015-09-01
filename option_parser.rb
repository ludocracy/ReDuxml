require 'optparse'
require 'optparse/time'
require 'ostruct'
require 'pp'

class Option_Parser
  #
  # Return a structure describing the options.
  #
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.user_info = nil
    options.templates = ['designos_template.xml', 'registry_template.xml']
    options.verbose = false

    opt_parser = OptionParser.new do |opts|
      opts.separator ""
      opts.separator "Specific options:"

      # templates to pass in; added to queue after launch template
      opts.on("-t", "--template [TEMPLATE]", Array,
              "Pass in template file(s)") do |template|
        options.templates << template
      end

      # pass in user info: must be Array of [id, password] format
      opts.on("-u", "--user [USER]", Array,
              "Provide user info") do |user|
        options.user_info = user
        #must have two items - id and password
        throw user if user.size != 2
      end

      # Boolean switch.
      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options.verbose = v
      end

      opts.separator ""
      opts.separator "Common options:"

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "See arguments and options") do
        puts opts
        exit
      end

      # Another typical switch to print the version.
      opts.on_tail("--version", "Show version") do
        puts ::Version.join('.')
        exit
      end
    end

    opt_parser.parse!(args)
    options
  end  # parse()

end  # class Option_Parser
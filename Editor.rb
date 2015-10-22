# Editor contains methods for user to interact with design - is a console in its unextended state; can be extended with graphical overlay or enterprise editing tool
module Editor
  require_relative 'Base_types'
  include Base_types
  # points to current Component
  @cursor
  # **************use these!!!!****************
  # ENV['USER']  on Unix
  # ENV['USERNAME'] on Windows


  def respond input
    case input[0]
      when 'help'
        puts "help check root child parent load quit"
      when 'quit'
        STDERR.puts "quitting"
        @cursor =
        quit
      when 'check'
        puts @cursor.summarize
      when 'root'
        @cursor = @root_template
      when 'child'
        maybe = @cursor.find_child input[1]
        @cursor = maybe || @cursor
      when 'parent'
        @cursor = @cursor.parent
      when 'build'
        @cursor.build
      else
        d "unknown command '# {input[0]}'"
    end
  end

  def listen
    until @cursor.nil? do
      puts "Command?"
      respond gets.chomp!.split' '
    end
  end

  def load root_xml_node, *args
    @cursor = @root_template = Template.new(root_xml_node)
    # temporarily bypassing Editor template
    listen
  end

  def root_name
    self.to_s
  end
end
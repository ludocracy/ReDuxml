#Editor contains methods for user to interact with design - is a console in its unextended state; can be extended with graphical overlay or enterprise editing tool
module Editor
  require_relative 'Base_types'
  include Base_types
  @root_component
  @cursor
  def self.help *args
    puts "help check root child parent load quit"
  end

  def self.quit *args
    STDERR.puts "quitting"
    @cursor = nil
  end

  def self.check *args
    puts @cursor.inspect
  end

  def self.root *args
    @cursor = @root_component
  end

  def self.child index
    maybe = @cursor.find_child index
    @cursor = maybe || @cursor
  end

  def self.parent *args
    @cursor = @cursor.parent
  end

  def self.build *args
    @cursor.build args
  end

  def self.view *args
    @cursor.view args
  end

  def self.load root_xml_node, *args
    @cursor = @root_component = Component.new(root_xml_node)
    listen
  end

  def listen
    until @cursor.nil? do
      puts "Command?"
      input = gets.chomp!.split' '
      begin
        Editor.send input[0], input[1]
      rescue NoMethodError
        STDERR.puts "unknown command '#{input[0]}'"
      end
    end
  end

  require_relative "Base_types"
  include Base_types
  require 'io/console'

  #load this editor's methods
  def load_editor editor_template_file
    #load template and load methods
    @editor_template = Template.new editor_template_file

    #redo this?!
    #should only make methods in the template public; all else should be made private so that user cannot call them
    @editor_template.child('methods').children.each do |method|
      @methods[method['name']] = method.xml_node.content
    end
    #zeroing out current template so user can load one
    @current_template = nil
  end
end
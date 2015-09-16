#Editor contains methods for user to interact with design - is a console in its unextended state; can be extended with graphical overlay or enterprise editing tool
module Editor
  require_relative "Base_types"
  include Base_types
  require 'io/console'

  @exit
  @user
  @editor_template
  @methods = {}

  #load this editor's methods
  def load_editor editor_template_file
    #load template and load methods
    @editor_template = Template.new editor_template_file

    #redo this?!
    #should only make methods in the template public; all else should be made private so that user cannot call them
    @editor_template.child('methods').children.each do |method|
      @methods[method['name']] = method.node_xpath.content
    end
    #zeroing out current template so user can load one
    @current_template = nil
  end

  #rewrite this!
  #if no current template ask for one; if no owner (default on startup) ask for one
  def edit open_template
    @current_template = open_template
    loop do
      #get user input
      user_input = STDIN.gets.chomp!
      #execute editor methods
      case user_input
        when 'quit'
          exit
        else
      end
      #methods we need:
      #one for each change: insert, remove,
    end
  end
end
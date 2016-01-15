require_relative 'patterns/template'
require_relative 'gardener'

module Chef
  include Templates

  def open filename
    @current_template = Template.new(File.open(filename))
  end

  def grow target
    Gardener.grow target
  end

  def wrap target, container

  end

  def goto direction
    # xpath
    # relative
  end

  def read filename
    @current_template = Template.new(File.read(filename))
  end

  def save target, filename=nil
    File.write(filename || @current_template.name, @current_template)
  end

  def template
    @current_template
  end

  def component
    @cursor
  end

  @current_template
  @cursor

  extend self
end
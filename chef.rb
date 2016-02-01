require_relative 'patterns/template'
require_relative 'tree_farm'
require 'nokogiri'

class DesignOS
  include Chef

  @cursor

  attr_accessor :cursor

  def initialize
    cursor = nil
    cook
  end
end

module Chef
  include Patterns
  ADDRESS_SCHEMA_FILE = '../rng/template.rng'

  def cook
    loop do
      input = gets.split(' ').keep_if do |a| a == ' ' end
      chef_methods = Chef.methods.keep_if do |m| m[0..4]=='chef_' end
      command = "chef_#{input.first}".to_sym
      args = input.size > 1 ? input[1..-1] : []
      case command
        when chef_methods.include?(command)
          cursor = send "chef_#{input.first}".to_sym, *args
        when 'exit', 'quit'
          return
        when 'cursor'
          puts cursor.nil? ? 'no target' : cursor.name
        else
          puts "unrecognized command."
      end
    end
  end

  def chef_open filename
    schema = Nokogiri::XML::RelaxNG File.open ADDRESS_SCHEMA_FILE
    xml_doc = Nokogiri::XML File.read filename
    template_root_node = schema.valid?(xml_doc) ? xml_doc.root : wrap(xml_doc.root)
    @current_template = Template.new template_root_node
  end

  def chef_grow target
    Gardener.grow target
  end

  def chef_goto direction
    # xpath
    # relative
  end

  def chef_save target, filename=nil
    File.write(filename || target.name, target)
  end

  private


  extend self
end
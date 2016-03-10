require File.expand_path(File.dirname(__FILE__) + '/../../Dux/dux/meta')
require File.expand_path(File.dirname(__FILE__) + '/design')

include Dux

class Meta < DuxObject
  def initialize xml_node=nil, args = {}
    super class_to_xml(xml_node), reserved: %w(history grammar design)
  end
end
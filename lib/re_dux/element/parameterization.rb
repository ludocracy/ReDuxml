require File.expand_path(File.dirname(__FILE__) + '/../../ruby_ext/string')

# methods to extend Dux::Object with methods needed to process parameterized XML content
module Parameterization
  # returns true if self[:if] is true or indeterminate (because condition is currently parameterized)
  # returns false otherwise i.e. this node does not exist in this design build
  def if?
    return true unless (if_str = xml[:if])
    if_str.parameterized? || if_str == 'true' ? true : false
  end

  # changes condition of this object's existence
  def if=(condition)
    # check for valid conditional
    change_attr_value :if, condition
  end
end # module Parameterization

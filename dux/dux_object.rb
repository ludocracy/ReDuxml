require File.expand_path(File.dirname(__FILE__) + '/../../Dux/dux/dux_object')

require File.expand_path(File.dirname(__FILE__) + '/dux_object/parameterization')

# XML-bound object; inherits Tree::TreeNode to gain access to more tree-traversal methods
class DuxObject
  include Parameterization
end # class Dux
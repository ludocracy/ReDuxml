#Builder contains methods for converting template files into design Components
#also has hooks for owners to create, modify, and otherwise manage templates via include File module
module Builder
  require_relative 'Base_types'
  require_relative 'resolver'
  include Resolver
  include Base_types
  #points to the component the builder is currently working on
  @cursor
  #holds parameters and their values as a smart hash
  @parameters
  #operator hash
  #@operator_hash
  #current template file - holds run-time history
  #it is a ghost (permutation) of the reference template passed by the Editor
  @current_template
  #contains methods to process parameter expressions; Component has methods to give up parameterized XML nodes

  #basic function of builder - takes a given Component, creates a clone object, then builds that out according it its parameters
  def build
    @cursor = self.clone
    unless @cursor.is_a? Template
      #creating new template to wrap around the wrapped component and track run time changes; owner is Builder
      @current_template = Template.new nil, {owner: self, wrapped: @cursor}
    end
    @current_template = @cursor
    @parameters = @current_template.design.get_params
    grow @cursor
    @builds[@current_template.object_id] = @current_template
    @cursor = @current_template.children[-1]
  end

  #recursive method that traverses down system design, pruning and instantiating
  def grow current_node
    @cursor = current_node
    @parameters.update @cursor.get_params if current_node.is_a? Instance

    #each node gets parameterized and instantiated or deinstantiated
    #parameterize should return the same node if unchanged; if changed return clone with parental preference for build clones and same children as reference
    current_node = parameterize current_node, @parameter_hash
    if current_node.children
      current_node.children.each do |child|
        grow child
      end
    end
    current_node
  end

  private :grow
end
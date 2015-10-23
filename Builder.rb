# Builder contains methods for converting template files into design Components
# also has hooks for owners to create, modify, and otherwise manage templates via include File module
module Builder
  require_relative 'Base_types'
  require_relative 'resolver'
  require_relative '../dentaku/lib/dentaku'
  include Dentaku
  include Base_types
  # points to the component the builder is currently working on
  @cursor
  # holds parameters and their values as a smart hash
  @parameters
  # operator hash
  # @operator_hash
  # current template file - holds run-time history
  # it is a ghost (permutation) of the reference template passed by the Editor
  @current_template
  # contains methods to process parameter expressions; Component has methods to give up parameterized XML nodes

  # basic function of builder - takes a Template (or Component, which it then wraps in a Template),
  # then builds that out according it its parameters
  def load
    @cursor = self.clone
    unless @cursor.is_a? Template
      # creating new template to wrap around the wrapped component and track run time changes; owner is Builder
      @current_template = Template.new nil, {owner: self, wrapped: @cursor}
    end
    @current_template = @cursor
    @parameters = @current_template.design.params

    Dentaku.set @current_template.design.logics
    build @cursor
    @builds[@current_template.object_id] = @current_template
    @cursor = @current_template.children[-1]
  end

  # recursive method that traverses down system design, pruning and instantiating
  def build current_node
    @cursor = current_node
    case current_node.class
      when Instance then @parameters.update @cursor.params
      when Template then build current_node.design
      when Design then @logics.update @cursor.logics
      else
        # each node gets parameterized and instantiated or deinstantiated
        # parameterize should return the same node if unchanged;
        # if changed return clone with parental preference for build clones and same children as reference
        parameterize! current_node
        if current_node.children
          current_node.children.each do |child|
            if Inspector.check current_node
              build child
            else
              # should wrap remove method so it returns change object
              child.remove_from_parent!
            end
          end
        end
    end
  end

  # takes a given node and resolves all of its parameterization
  def parameterize! current_node
    working_node = current_node.dup
    working_node.get_parameterized_xml_nodes.each do |xml_node|
      content_str = xml_node.content.to_s
      question = find_expr content_str
      reply = Dentaku.evaluate(question, @parameters)
      xml_node.content = content_str.gsub(question, reply)
    end
    current_node = working_node
  end

  def find_expr str
    expr_start_index = str.index'@('
    expr_end_index = find_close_parens_index str[expr_start_index,-1]
    str[expr_start_index, expr_end_index]
  end

  def find_close_parens_index str
    levels = 0
    str.to_ary.each_with_index do |char|
      if index == 0
        levels += 1
        next
      end
      case char
        when '(' then levels += 1
        when ')' then levels -= 1
        else next
      end
      return index if levels == 0
    end
    raise Exception, "cannot find end of parameter expression!"
  end

  private :build, :parameterize!, :find_expr
end
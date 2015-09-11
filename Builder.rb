#Builder contains methods for converting template files into design Components
#also has hooks for owners to create, modify, and otherwise manage templates via include File module
module Builder
  #all modules need the Base types of DesignOS (Component, Template and their basic subclasses)
  require_relative "Base_types"
  #Symbolic gem allows evaluation of parameter expressions with unresolved parameters
  #WTF? i have to put full path to get linker to find it!
  require 'C:/Ruby21-x64/lib/ruby/gems/2.1.0/gems/symbolic-0.3.8/lib/symbolic.rb'
  #methods include redefines of common algebraic and string methods
  include Symbolic
  include Base_types

  #holds views user can access this iteration
  @views = [nil]
  #holds builder template; adds overrides or new methods in addition to the ones defined below
  @builder_template
  #current build process
  @build
  #holds parameters and their values at the current iteration
  @parameter_hash
  #operator hash
  @operator_hash
  #current template file - holds run-time history of parameter redefines and instantiations
  @current_template

  #loads this builder's basic features from builder template file
  def load_builder builder_template_file
    @builder_template = Template.new builder_template_file
  end

  #basic function of builder - takes a Template and builds it out according it its parameters
  def build open_template
    #each method takes the current tree's system (design) and
    #removes non-viewable elements, resolves parameters, and instantiates children
    instantiate parameterize prune open_template.system
  end

  #makes sure this node can be seen by one of the views; returns nil otherwise
  def prune current_node
    #loop through each view
    @views.each do |view|
      #return the moment we find a view that can see this node
      return view.can_see current_node
    end
  end

  #if this node is an instance type add parameter definitions to hash
  #replace instances of known parameters in expressions with hashed values, evaluate/simplify expressions
  def parameterize current_node
    #add this nodes parameter hash to the template's -
    if current_node.is_a? 'Instance'
      @parameter_hash.merge! current_node.parameters do |param_name, old_value, new_value|
        #add parameter redefine to run-time history of this template
        #NOT DONE YET! need to build out history API first!!!
      end
    end
    #traversing template tree XML and replacing all
    current_node.node_xpath.traverse do |node|
      #get an array of macro strings and loop through them
      Array macro_strings = node.get_macro_strings.each do |macro_string|
        #looping through each known parameter from hash
        @parameter_hash.keys.each do |key|
          #replace parameters with values in given macro string
          macro_string[key.to_s] = @parameter_hash[key]
        end
        #simplify result, retaining unknown value parameters as strings
        results = simplify macro_string
        node.resolve_element results[0]
        #add removal of returned cancelled parameters to template's run-time history
        #record_remove results[1...-1]
      end
    end
  end

  #uses Symbolic gem to leave parameters with unknown values intact while resolving remaining terms
  #simplify result, retaining unknown value parameters as strings
  def simplify macro_string
    #find potential parameters and remove duplicates
    potential_vars = macro_string.scan(/\b[a-z][a-zA-Z0-9_]*/)
    #remove duplicates
    potential_vars.uniq!
    #remove any that are actually operators
    #potential_vars.keep_if do |identifier| @operator_hash.keys.include? identifier end
    #declare them as symbolic vars and add '@' to each in macro string
    potential_vars.to_a.each do |variable|
      puts variable
      #have to convert into an instance variable name
      instance_var_name = "@#{variable}"
      #replace in macro string
      macro_string.gsub! variable, instance_var_name
      #declare as instance variable of type Symbolic::Variable
      instance_variable_set(instance_var_name, Variable.new(:name => variable))
    end
    #evaluate expression and return
    result_str = (eval macro_string).to_s
    #check for parameters that were cancelled out and add to array
    cancelled_parameters = []
    potential_vars.each do |var|
      #result string no longer contains variable! return it with result!
      if !result_str.include? var
        cancelled_parameters << var
      end
    end
    #return both result and array of cancelled parameters
    return result_str, cancelled_parameters
  end

  #what to do if Component consists of array of arrays?
  def instantiate current_node
    #look for if=false
    current_node.node_xpath.traverse do |node|
      if node['if'] == 'false'
        #remove the whole thing
        throw :deinstantiation, node
      end
      case node.name
        when 'instance'

          #find reference and import elements
          #pass on params
        when 'array'
        else
      end

    end
    ##if array loop and create concrete children
    #if instance load ref and iterate
  end

  #used by build method; not by OS
  private :simplify, :prune, :parameterize, :instantiate
end
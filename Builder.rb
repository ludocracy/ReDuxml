#Builder contains methods for converting template files into design Components
#also has hooks for owners to create, modify, and otherwise manage templates via include File module
module Builder
  module Parameterize
    require 'symbolic'
    include Symbolic
#prepares an expression to have its parameter expressions evaluated
    def find_expr input_string
      index = input_string.index('@(')
      close_index = find_close_parens_index input_string[index...-1]
      input_string[(index+2)...(close_index-1)]
    end

    def parameterize current_node
      STDERR.puts "parameterizing"
      if !@parameter_hash.is_a? Hash
        STDERR.puts "creating new parameter_hash!"
        @parameter_hash = Hash.new
      end
      #add this nodes parameter hash to the template's -
      if current_node.element == "parameter"
        STDERR.puts "found a parameter assignment: #{current_node.xml['name']}=#{current_node.xml['value'].to_s}!"
        @parameter_hash[current_node.xml['name']] = current_node.xml['value']
        #add parameter redefine to run-time history of this template
      end
      #get an array of parameterized xml nodes and loop through them
      current_node.get_parameterized_xml_nodes.each do |parameterized_xml_node|
        macro_string = find_expr parameterized_xml_node.content
        STDERR.puts "found a macro_string: '#{macro_string}'!"
        #looping through each known parameter from hash
        @parameter_hash.keys.each do |key|
          STDERR.puts "swapping in value of '#{key.to_s}'!"
          #replace parameters with values in given macro string
          macro_string[key.to_s] = @parameter_hash[key]
        end
        #simplify result, retaining unknown value parameters as strings
        results = simplify macro_string
        STDERR.puts "resolved to: '#{results[0]}'!"
        parameterized_xml_node.content["@(#{macro_string})"] = results[0]
        #add removal of returned cancelled parameters to template's run-time history
        #record_remove results[1...-1]
      end
      current_node
    end


    #had to create my own close parentheses finder
    def find_close_parens_index string
      #tracks current index of string
      pos = 0
      #tracks how many parentheses deep we're nested
      parens_depth = 0
      #looping through each char
      string.each do |char|
        case char
          #found a close parenthesis
          when ')'
            #move down a level
            parens_depth -= 1
            throw :close
          #found an open parenthesis
          when '('
            #move up a level
            parens_depth += 1
            throw :iterate
          else
            throw :iterate
        end

        #do this whenever close parenthesis found
        catch :close do
          case parens_depth
            #depth is 0 - we found it!
            when 0
              #return current char index
              return pos
            #how'd we go negative?
            when parens_depth < 0
              #throw an error - this needs to generate an error if user does not correct!
              throw :too_many_close_parens, 'parentheses error! too many close parentheses!'
            else
          end
        end

        #increment position index
        catch :iterate do
          pos += 1
        end
      end #end of string loop

      #method should not get here unless it never found enough close parentheses
      throw :too_many_open_parens, 'parentheses error! too many open parentheses!'
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
  end

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
  #holds parameters and their values at the current iteration
  @parameter_hash
  #operator hash
  @operator_hash
  #current template file - holds run-time history of parameter redefines and instantiations
  @current_template

  def d object
    inspection_str = ''
    quotes = ''
    if object.is_a? String
      quotes = '"'
    else
      inspection_str = ".inspect = #{object.inspect}"
    end
    STDERR.puts "#{object.class.to_s}::#{quotes + ObjectSpace._id2ref(object.object_id).to_s + quotes}" + inspection_str
  end

  #loads this builder's basic features from builder template file
  def load_builder builder_template_file
    @builder_template = Template.new builder_template_file
  end

  #basic function of builder - takes a Template and builds it out according it its parameters
  def build open_template
    STDERR.puts "#{__LINE__} working with template: #{open_template.full_name}"
    #each method takes the current tree's system (design) and
    #removes non-viewable elements, resolves parameters, and instantiates children
    #don't forget to wrap the return value in a template again!
    @current_template = open_template
    #need to finish user/owner design first!
    #@views = @current_template.owners.views
    #returns a grown design
    @parameter_hash = Hash.new
    open_template.system = grow open_template.system
    open_template
  end



  #recursive method that traverses down system design, pruning and instantiating
  def grow current_node
    #each node gets put through the loop and emerges as more concrete version of itself
    current_node = instantiate parameterize prune current_node
    if current_node.children
      current_node.children.each do |child|
        grow child
      end
    end
    current_node
  end



  #makes sure this node can be seen by one of the views; returns nil otherwise
  #finish when you've got users and views working!!!
  def prune current_node
    #loop through each view
    #@views.each do |view|
      #return the moment we find a view that can see this node
      #return view.can_see current_node
    #end
    current_node
  end

  #if this node is an instance type add parameter definitions to hash
  #replace instances of known parameters in expressions with hashed values, evaluate/simplify expressions
  def parameterize current_node
    #add this nodes parameter hash to the template's -
    if current_node.is_a? Instance
      if current_node.parameter_hash
        @parameter_hash.merge! current_node.parameter_hash do |param_name, old_value, new_value|
          old_value = new_value
          #throw param_name to history
        end
        #add parameter redefine to run-time history of this template
        #NOT DONE YET! need to build out history API first!!!
        STDERR.puts "#{__LINE__} parameterize has loaded the following : #{current_node.parameter_hash.inspect}"
      end
    end
    #traversing template tree XML and replacing all

    #get an array of macro strings and loop through them
    current_node.get_macro_strings.each do |macro_string|
      #looping through each known parameter from hash
      @parameter_hash.keys.each do |key|
        #replace parameters with values in given macro string
        macro_string[key.to_s] = @parameter_hash[key]
      end
      #simplify result, retaining unknown value parameters as strings
      results = simplify macro_string
      current_node.resolve_element results[0]
      #add removal of returned cancelled parameters to template's run-time history
      #record_remove results[1...-1]
    end
    current_node
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
    current_node.xml_node.traverse do |node|
      if node.is_a? Nokogiri::XML::Element
        if node['if'] == 'false '
          #remove the whole thing
          throw :deinstantiation, node
        end
        case node.name
          when 'instance'
            #find reference and import elements
            #add as concrete child
            #pass on params
          when 'array'
            #loop and create patterned instances as concrete children
            node
          else
        end
      end
    end
    ##if array loop and create concrete children
    #if instance load ref and iterate
    current_node
  end

  #used by build method; not by OS
  private :simplify, :prune, :parameterize, :instantiate
end
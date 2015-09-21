#Builder contains methods for converting template files into design Components
#also has hooks for owners to create, modify, and otherwise manage templates via include File module
module Builder
  require_relative 'Base_types'
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
  module Parameterize
    require 'symbolic'
    include Symbolic

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
    #may want to expose this particular method because it's just so damn useful!
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

    private :parameterize, :find_close_parens_index, :simplify
  end

  #basic function of builder - takes a given Component, creates a clone object, then builds that out according it its parameters
  def build reference_node
    @parameters = Parameters.new nil
    @cursor = reference_node.dup
    unless @cursor.is_a? Template
      #creating new template to wrap around the wrapped component and track run time changes; owner is Builder
      @current_template = Template.new nil, {owner: self, wrapped: @cursor}
    end
    @current_template = @cursor
    grow @cursor
    reference_node.add_build @current_template
    @cursor = @current_template.children[-1]
  end

  #recursive method that traverses down system design, pruning and instantiating
  def grow current_node
    if current_node.is_a? Instance
      @parameters.update @cursor.get_params
    end

    #each node gets parameterized and instantiated or deinstantiated
    current_node = parameterize current_node
    if current_node.children
      current_node.children.each do |child|
        grow child
      end
    end
    current_node
  end

  private :grow
end
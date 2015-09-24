module Resolver
  require_relative 'symbolic_modified/symbolic'
  include Symbolic

  def get_logics current_node
    if current_node.is_a? Design
      current_node[:logics]
    else
      default_logics
    end
  end

  def default_logics
    operators = []
    [:string, :boolean, :arithmetic].each do |logic|
      operators << @logic_hash[logic]
    end
    operators
  end

  def parameterize current_node, param_hash
    @logic_hash = get_logics current_node
    reference_node = current_node
    current_node = reference_node.clone
    changed = false
    #get an array of parameterized xml nodes and loop through them
    current_node.get_parameterized_xml_nodes.each do |parameterized_xml_node, paramized_string|
      macro_strings = find_expr paramized_string
      macro_strings.each do |macro_string|
        STDERR.puts "found a macro_string: '#{macro_string}'!"
        if param_hash.is_a? Hash
          #looping through each known parameter from hash
          param_hash.keys.each do |key|
            STDERR.puts "swapping in value of '#{key.to_s}'!"
            #replace parameters with values in given macro string
            #need to add s
            if macro_string[key.to_s]
              changed ||= true
              macro_string[key.to_s] = param_hash[key]
            end
          end
        end
        #simplify result, retaining unknown value parameters as strings
        results = simplify macro_string
        STDERR.puts "resolved to: '#{results[0]}'!"
        parameterized_xml_node.content["@(#{macro_string})"] = results[0]
        #add removal of returned cancelled parameters to template's run-time history
        #record_remove results[1...-1]
      end
    end
    if changed
      current_node
    else
      reference_node
    end
  end

  def find_expr string
    macro_strings = []
    fragments = string.split('@(')
    fragments.each_with_index do |fragment, index|
      if index == 0
        next
      end
      d fragment
      close_index = find_close_parens_index "(#{fragment}"
      macro_strings << fragment[0...(close_index-1)]
    end
    d macro_strings
    macro_strings
  end

  #had to create my own close parentheses finder
  def find_close_parens_index string
    #tracks current index of string
    pos = 0
    #tracks how many parentheses deep we're nested
    parens_depth = 0
    #looping through each char
    string.split(//).each_with_index do |char, index|
      case char
        #found a close parenthesis
        when ')'
          #move down a level
          parens_depth -= 1
        #found an open parenthesis
        when '('
          #move up a level
          parens_depth += 1
        else
      end
      case parens_depth
        #depth is 0 - we found it!
        when 0
          #return current char index
          return index
        #how'd we go negative?
        when parens_depth < 0
          #throw an error - this needs to generate an error if user does not correct!
          throw :too_many_close_parens, 'parentheses error! too many close parentheses!'
        else
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
    #***********need to screen for legal operators and methods here!!!
    potential_vars = macro_string.scan(/\b[a-z][a-zA-Z0-9_]*/)
    #remove duplicates
    potential_vars.uniq!
    #remove any that are actually operators
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

  private :parameterize, :find_close_parens_index, :find_expr
end

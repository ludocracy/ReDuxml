#Builder contains methods for converting template files into design Components
#also has hooks for owners to create, modify, and otherwise manage templates via include File module
module Builder
  require_relative "Base_types"
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

  #loads this builder's basic features from builder template file
  def load_builder builder_template_file
    @builder_template = Template.new builder_template_file
  end

  #basic function of builder - takes a Template and builds it out according it its parameters
  def build open_template
    open_template.
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

  #find parameter definitions and
  def parameterize current_node
    #find parameter assignments and add to hash
    @parameter_hash << current_node.child(:parameter)
    #traversing template tree XML and replacing all
    current_node.node_xpath.traverse do |node|
      #get an array of macro strings and loop through them
      Array macro_strings = node.get_macro_strings.each do |macro_string|
        #looping through each known parameter from hash
        @parameter_hash.keys.each do |key|
          #replace parameters with values in given macro string
          macro_string[key.to_s] = @parameter_hash[key]
        end
      end
      #evaluate macro strings as code and return resolved expressions
      Hash resolved_values
      macro_strings.each do |macro_string|
        #marking up macro string for operators and unresolved parameters and stripping outer delimiters i.e. @(...)
        marked_up_macro_string = markup(markup(macro_string, @operator_hash.keys, '#'), /\b[a-z][_a-zA-Z0-9]*/, ':')[2...-1]
        #resolve marked up macro string and add cleaned up expression or value to hash
        resolved_values[macro_string] = eval_expr marked_up_macro_string
      end

      #change element's parameterized content to resolved expressions
      node.resolve_element resolved_values
    end
  end

  #take given macro strings and evaluates, returning resolved value - may still contain unresolved parameter expressions!
  #can we make this recursive so we don't have to worry about parentheses?
  def eval_expr macro_string
    #stack of operations (should not ever exceed 2!)
    operator_stack = []
    #last parameter found
    last_parameter_expr = ''
    #last value expression
    last_value_expr = ''
    #array of terms that come in two types: unsolvable (parameter expressions) and resolved expressions (value)
    expressions = []
    iterator = 0
    loop do
      case macro_string[iterator]
        #found a subexpression
        when '('
          #extract it - subtracting open and close parentheses
          sub_expr = macro_string[iterator + 1 ... find_close_parens_index(macro_string) - 1]
          #recurse to evaluate and replace with result
          resolved_sub_expr = eval_expr sub_expr
          #replace sub_expr plus parentheses with resolved sub_expr
          macro_string['(' + sub_expr + ')'] = resolved_sub_expr
          #bumping iterator up by length of replacement expression/value
          iterator += resolved_sub_expr.size
        #found an operator
        when '#'
          #find end of operator
          end_delimiter_index = macro_string[iterator+1...-1].find_index('#')
          operator = macro_string[iterator...end_delimiter_index]
          #we have a previous parameter
          if last_parameter_expr
            #add this operator to last parameter's expression and add to expressions
            expressions << last_parameter_expr + operator
            #empty last_parameter for next one
            last_parameter_expr.clear
            #we don't have a previous parameter
          else
            #push onto operator stack
            operator_stack << operator
          end
          #incrementing by size of operator
          iterator += operator.size
        #found a parameter
        when ':'
          #find end of parameter
          end_delimiter_index = macro_string[iterator+1...-1].find_index(':')
          #add each preceding operator before parameter
          operator_stack.each do |operator|
            last_parameter_expr += operator
          end
          #emptying stack
          operator_stack.clear
          #add parameter
          last_parameter_expr += macro_string[iterator...end_delimiter_index]
          #increment iterator by size of parameter
          iterator += last_parameter_expr.size
        #ignore whitespace
        when ' '
          #do nothing
          #found something other than an operator or parameter - must be an actual value; lots of code in common with parameter handling! combine somehow??
        else
          #empty parameter expression
          last_parameter_expr.clear
          #finding end of value (just before beginning of next operator)
          end_delimiter_index = macro_string[iterator...-1].find_index('#') - 1
          if last_value_expr
            #add each preceding operator before value to value expression
            operator_stack.each do |operator|
              last_value_expr += operator
            end
            #emptying stack
            operator_stack.clear
          end
          #adding the value we found
          last_value_expr += macro_string[iterator...end_delimiter_index]
          #we now have a resolvable expression - evaluate as code and convert to string
          result_str = eval(last_value_expr).to_s
          #overwrite expression with result
          macro_string[last_value_expr] = result_str
          #increment iterator by result's size
          iterator += result_str.size
          #set last_value_expr to result
          last_value_expr = result_str
      end
      iterator += 1
    end

  end

  #takes given string and, according to given criteria, marks various substrings with given delimiters
  def markup macro_string, *criteria, delimiter
    #go through each criteria string
    criteria.each do |criterion|
      #get array of matches
      macro_string.scan(criterion).each do |match|
        #add delimiter chars and spacing around each match
        macro_string[match] = ' ' + delimiter + match + delimiter + ' '
      end
    end
    macro_string
  end

  #what to do if Component consists of array of arrays?
  def instantiate current_node
    #look for if=false
    current_node.node_xpath.traverse do |node|
      if node['if'] == 'false'
        #remove the whole thing
        throw :deinstantiation
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
end
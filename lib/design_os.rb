require File.expand_path(File.dirname(__FILE__) + '/symja_ext/symja')
require File.expand_path(File.dirname(__FILE__) + '/ruby_ext/macro')
require File.expand_path(File.dirname(__FILE__) + '/../../Dux/lib/dux')

# contains Dux module, allowing multiple XML files to be worked on concurrently
class Duxer
  include Dux

  def initialize
    @dux_array = []
  end
end

module Dux
  @dux_array
  @cursor

  attr_reader :dux_array, :cursor

  # generates new design tree from current lib, resolving parameter values and instantiating Instance objects, and pruning filtered objonents.
  def resolve
    grow!
    prune!
    current_meta
  end

  # metadata corresponding to original XML design file
  def base_meta
    @dux_array.first
  end

  # metadata for current build of design
  def current_meta
    @dux_array.last
  end

  # pushes new build onto stack of design builds
  def dux(metaxml_or_design, xml=nil)
    new_dux = xml.nil? ? Meta.new << metaxml_or_design : Meta.new(metaxml_or_design.root << xml)
    @dux_array << new_dux
  end

  private

  # if current_node is an Instance, then calls its #instantiate and replaces it with the results
  # unfolding Arrays, and replacing references with copies
  def instantiate!(current_node)
    @cursor = current_node
    if current_node.respond_to?(:params)
      current_node.instantiate(base_meta).each do |new_node|
        unless current_node.find_child(new_node.id) || current_node.id == new_node.id
          current_node << new_node
        end
      end
    end
  end

  # traverses tree recursively, resolving parameters and instantiating new children along the way
  def grow!(current_node=nil)
    @cursor = current_node
    if current_node.nil?
      dux base_meta.design
      current_meta << element('description', 'grown')
      grow! current_meta.design
    else
      resolve_parameterized! current_node
      current_node.children.each do |child|
        if peek child
          instantiate! child
          grow! child
        end
      end
    end
  end

  # resolves all parameteterization in current node using current parameter values
  def resolve_parameterized!(current_node, attr=nil)
    @cursor = current_node
    parameterized_xml_nodes = if attr.nil?
                                current_node.parameterized_xml_nodes
                              else
                                [current_node.xml.attribute(attr.to_s)]
                              end
    parameterized_xml_nodes.each do |xml_node|
      param_hash = get_param_hash current_node
      content_str = xml_node.content.to_s
      xml_node.content = resolve_str content_str, param_hash
    end
    current_node
  end # def resolved_parameterized!

  # removes nodes whose @if is now false
  def prune!
    dux current_meta.design.stub
    current_meta << element('description', 'pruned')
    previous.design.each do |node|
      next if reserved_node?(node)
      ref_parent = find_non_inst_ancestor node
      new_parent = current_meta.find ref_parent
      @cursor = new_parent
      new_kid = node.stub
      # TODO new_kid.xml.remove_attribute 'if'
      begin
        new_parent << new_kid
      rescue RuntimeError
        new_id = "#{new_kid.id}.#{node.parent.id}"
        new_kid.rename new_id # TODO didn't we get rid of #rename ?
        retry
      end
    end # previous.design.each do
  end # def prune!

  # finds index of close parentheses corresponding to first open parentheses found in given str
  def find_close_parens_index(str)
    levels = 0
    index = 0
    str.each_char do |char|
      case char
        when '(' then
          levels += 1
        when ')' then
          levels -= 1
        else
      end
      return index if levels == 0
      index += 1
    end
    raise Exception, "cannot find end of parameter expression!"
  end

  # takes given potentially parameterized string, applies given param_hash's values, then resolves parameter expressions
  # returning resolved result
  def resolve_str(content_str, param_hash)
    question = find_expr content_str
    return content_str if question.nil?
    reply = Macro.new Symja.instance.evaluate(question, param_hash)
    replacement_str = reply.parameterized? ? reply : reply.demacro
    macro_string = Macro.new(question)
    content_str.gsub(macro_string, replacement_str)
  end

  # finds macro expression within given string
  # e.g. find_expr 'asdf @(param) asdf' => 'param'
  def find_expr(str)
    expr_start_index = str.index('@(')
    return nil if expr_start_index.nil?
    expr_end_index = find_close_parens_index str[expr_start_index+1..-1]
    str[expr_start_index+2, expr_end_index-1]
  end

  # peeks at current node to see if given current param values it will exist or not
  def peek(current_node)
    if current_node[:if].nil? || current_node.simple_class.include?('parameter')
      true
    else
      r = resolve_parameterized!(current_node, :if)
      r.if?
    end
  end

  # gets ancestry of given node of just Instance ancestors
  def get_inst_hierarchy(node)
    h = []
    node.parentage.each do |ancestor|
      h << ancestor if ancestor.respond_to?(:params)
    end
    h
  end

  # gets parameter value hash that has scope for given object
  def get_param_hash(node)
    h = {}
    inst_hierarchy = get_inst_hierarchy node
    inst_hierarchy.each do |inst|
      if inst.params && inst.params.any?
        inst.params.each do |param|
          param_name = param[:name]
          next unless param_name
          new_value = param[:value]
          old_val = h[param_name.to_sym]
          if old_val && old_val != new_value
            param.value = new_value
          end
          h[param_name.to_sym] = new_value
        end
      end
    end
    h
  end

  # returns true if any of given node's ancestors do not exist
  def dead_node?(node)
    cur = node
    until cur.simple_class == 'design' || cur.nil?
      return true unless cur.if?
      cur = cur.parent
    end
    false
  end

  # TODO replace with Rule!
  # checks if node is one of few types not allowed to contain parameterization
  def reserved_node?(node)
    node.descended_from?('parameters') || node.simple_class == 'parameters' ||
        node.simple_class == 'design' || dead_node?(node) || node.respond_to?(:params)
  end

  # returns first ancestor that is NOT an Instance
  def find_non_inst_ancestor(node)
    cur = node.parent
    return if cur.nil?
    if cur.respond_to?(:params) && cur.simple_class != 'design'
      find_non_inst_ancestor cur
    else
      cur
    end
  end

  # returns previous build
  def previous
    dux_array[-2]
  end
end # module Dux

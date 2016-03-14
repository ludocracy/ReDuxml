require File.expand_path(File.dirname(__FILE__) + '/symja_ext/symja')
require File.expand_path(File.dirname(__FILE__) + '/ruby_ext/macro')
require File.expand_path(File.dirname(__FILE__) + '/dux_ext/meta')
require File.expand_path(File.dirname(__FILE__) + '/../../Dux/lib/dux')

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
# generates new design tree from current lib, resolving parameter values and instantiating Instance objects, and pruning filtered components.
  def resolve
    grow!
    prune!
    current_dux
  end

  def base_dux
    @dux_array.first
  end

  def current_dux
    @dux_array.last
  end

  def dux metaxml_or_design, xml=nil
    new_dux = xml.nil? ? Meta.new << metaxml_or_design : Meta.new(metaxml_or_design.root << xml)
    @dux_array << new_dux
  end

  private

  def instantiate! current_node
    @cursor = current_node
    if current_node.respond_to?(:params)
      current_node.instantiate(base_dux).each do |new_node|
        unless current_node.find_child(new_node.id) || current_node.id == new_node.id
          current_node << new_node
        end
      end
    end
  end

  def grow! current_node=nil
    @cursor = current_node
    if current_node.nil?
      dux base_dux.design
      current_dux.rename 'grown'
      grow! current_dux.design
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

  def resolve_parameterized! current_node, attr=nil
    @cursor = current_node
    parameterized_xml_nodes = if attr.nil?
                                current_node.parameterized_xml_nodes
                              else
                                [current_node.xml_root_node.attribute(attr.to_s)]
                              end
    parameterized_xml_nodes.each do |xml_node|
      param_hash = get_param_hash current_node
      content_str = xml_node.content.to_s
      xml_node.content = resolve_str content_str, param_hash
    end
    current_node
  end # def resolved_parameterized!

  def prune!
    dux current_dux.design.stub
    current_dux.rename 'pruned'
    previous.design.each do |node|
      next if reserved_node?(node)
      ref_parent = find_non_inst_ancestor node
      new_parent = current_dux.find ref_parent
      @cursor = new_parent
      new_kid = node.stub
      begin
        new_parent << new_kid
      rescue RuntimeError
        new_id = "#{new_kid.id}.#{node.parent.id}"
        new_kid.rename new_id
        retry
      end
    end # previous.design.each do
  end # def prune!

  def find_close_parens_index str
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

  def resolve_str content_str, param_hash
    question = find_expr content_str
    return content_str if question.nil?
    reply = Macro.new Symja.instance.evaluate(question, param_hash)
    replacement_str = reply.parameterized? ? reply : reply.demacro
    macro_string = Macro.new(question)
    content_str.gsub(macro_string, replacement_str)
  end

  def find_expr str
    expr_start_index = str.index('@(')
    return nil if expr_start_index.nil?
    expr_end_index = find_close_parens_index str[expr_start_index+1..-1]
    str[expr_start_index+2, expr_end_index-1]
  end

  def peek current_node
    if current_node[:if].nil? || current_node.simple_class.include?('parameter')
      true
    else
      r = resolve_parameterized!(current_node, :if)
      r.if?
    end
  end

  def get_inst_hierarchy node
    h = []
    node.parentage.each do |ancestor|
      h << ancestor if ancestor.respond_to?(:params)
    end
    h
  end

  def get_param_hash comp
    h = {}
    inst_hierarchy = get_inst_hierarchy comp
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

  def dead_node? node
    cur = node
    until cur.simple_class == 'design' || cur.nil?
      return true unless cur.if?
      cur = cur.parent
    end
    false
  end

  def reserved_node? node
    node.descended_from?('parameters') || node.simple_class == 'parameters' ||
        node.simple_class == 'design' || dead_node?(node) || node.respond_to?(:params)
  end

  def find_non_inst_ancestor node
    cur = node.parent
    return if cur.nil?
    if cur.respond_to?(:params) && cur.simple_class != 'design'
      find_non_inst_ancestor cur
    else
      cur
    end
  end

  def previous
    dux_array[-2]
  end
end

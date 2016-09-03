# Copyright (c) 2016 Freescale Semiconductor Inc.
require File.expand_path(File.dirname(__FILE__) + '/ruby_ext/macro')
require File.expand_path(File.dirname(__FILE__) + '/re_duxml/evaluate')
require File.expand_path(File.dirname(__FILE__) + '/re_duxml/element')
require 'con_duxml'

module ReDuxml
  include ConDuxml

  # @param doc_or_path [Doc, String] XML to load; can be Doc, String path or String XML
  # @return [Doc] instantiated XML with parameters resolved with given values
  def resolve(doc_or_path, opts={})
    @e = Evaluator.new()
    @src_doc = get_doc doc_or_path
    @doc = Doc.new << src_doc.root.instantiate do |node|
      if node.is_a?(String)
        resolve_str(node, get_params(node))
      else
        resolved_attrs = {}
        node.attributes.each do |attr, val| resolved_attrs[attr] = resolve_str(val, get_params(node)) end
        resolved_node = Element.new(node.name, resolved_attrs)
        if resolved_node.if?
          resolved_node[:if] = nil if resolved_node[:if] == 'true'
          resolved_node.instantiate
        end
      end
    end
  end

  attr_reader :e, :src_doc
  private

  # @param node [Element] a given element is expected to have child <parameters/> with grandchildren <parameter/>
  # @return [Hash] returns parameter values as hash
  def get_params(node)
    # TODO how to make this recursive? need to collect overrides!!
  end

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
    reply = Macro.new e.evaluate(question, param_hash)
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
end # module Dux

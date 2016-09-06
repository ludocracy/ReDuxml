# Copyright (c) 2016 Freescale Semiconductor Inc.
require File.expand_path(File.dirname(__FILE__) + '/ruby_ext/macro')
require File.expand_path(File.dirname(__FILE__) + '/re_duxml/evaluate')
require File.expand_path(File.dirname(__FILE__) + '/re_duxml/element')
require 'con_duxml'

module ReDuxml
  include ConDuxml

  # @param doc_or_node [Doc, String] XML to load; can be Doc, String path or String XML; also XML Element when recursing
  # @return [Doc] instantiated XML with parameters resolved with given values
  def resolve(doc_or_node, params={})
    if doc_or_node.is_a?(Element)
      resolved_attrs = {}
      new_params = get_params(doc_or_node, params)
      resolved_node = Element.new(doc_or_node.name, resolved_attrs)
      new_children = doc_or_node.nodes.collect do |src_node|
        if src_node.respond_to?(:nodes)
          resolved_child = src_node.stub
          resolved_child.attributes.each do |attr, val| resolved_child[attr] = resolve_str(val, new_params) end
          if resolved_node.if?
            resolved_node[:if] = nil if resolved_node[:if] == 'true'
            resolved_node.activate.collect do |inst| resolve inst end
          end
        else
          resolve_str(src_node, new_params)
        end
      end.flatten.compact
      if new_children.any?
        resolved_node << new_children
      end
      resolved_node
    else
      @e ||= Evaluator.new
      @src_doc = get_doc doc_or_node
      @doc = Doc.new << resolve(src_doc.root, params)
    end
  end

  attr_reader :e, :src_doc
  private


  def get_params(node, param_hash)
    if node.nodes.any? do |child| child.name == 're_duxml:parameters' end
      local_params = {}
      params = node.parameters.nodes.clone
      params.each do |param|
        name = param[:name]
        val = param[:value]
        new_val = resolve_str(param_hash, val)
        parameters.remove param unless new_val.parameterized?
        local_params[name] = new_val
      end
      node.remove parameters unless node.parameters.nodes.any?
      param_hash.merge local_params
    else
      param_hash
    end
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

  # @param content_str [String] string that may contain parameterized expressions e.g. "a @(var0+var1) string @(var2)"
  # @param param_hash [Hash] keys are parameter names, values are parameter values e.g. {var0: 'param', var1: 'eter'}
  # @return [String] content_str with parameter values substituted and algebraically reduced if any unknown parameters remain e.g. 'a parameter string @(var2)'
  def resolve_str(content_str, param_hash)
    question = find_expr content_str
    return content_str if question.nil?
    reply = Macro.new e.evaluate(question, param_hash)
    replacement_str = reply.parameterized? ? reply : reply.demacro
    macro_string = Macro.new(question)
    content_str.gsub(macro_string, replacement_str)
  end

  # @param str [String] string that may contain parameter expression e.g. 'asdf @(param + 2) asdf'
  # @return [String] macro string e.g. 'asdf @(param + 2) asdf' => 'param + 2'
  def find_expr(str)
    expr_start_index = str.index('@(')
    return nil if expr_start_index.nil?
    expr_end_index = find_close_parens_index str[expr_start_index+1..-1]
    str[expr_start_index+2, expr_end_index-1]
  end
end # module Dux

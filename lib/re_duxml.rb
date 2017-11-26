# Copyright (c) 2016 Freescale Semiconductor Inc.
require File.expand_path(File.dirname(__FILE__) + '/ruby_ext/macro')
require File.expand_path(File.dirname(__FILE__) + '/re_duxml/evaluate')
require File.expand_path(File.dirname(__FILE__) + '/re_duxml/element')
require File.expand_path(File.dirname(__FILE__) + '/re_duxml/array')
require 'con_duxml'

module ReDuxml
  include ConDuxml

  # @param doc_or_node [Doc, String] XML to load; can be Doc, String path or String XML; also XML Element when recursing
  # @return [Doc] instantiated XML with parameters resolved with given values
  def resolve(doc_or_node, parent_params={})
    @e ||= Evaluator.new
    if doc_or_node.is_a?(Element)
      resolved_node = doc_or_node.stub
      resolved_node.attributes.each do |attr, val|
        resolved_node[attr] = resolve_str(val, parent_params)
      end
      this_params = get_params(doc_or_node, parent_params)
      new_children = doc_or_node.nodes.collect do |child|
        if child.respond_to?(:nodes) # if this node is an XML element...
          new_child = child.clone
          new_child[:if] = resolve_str(new_child[:if], this_params) if new_child[:if]
          if new_child.if? # if this node should exist
            new_child[:if] = nil if new_child[:if] == 'true'
            child_params = get_params(new_child, this_params)
            new_instances = new_child.activate
            i = -1
            new_instances.collect do |inst|
              i += 1
              resolve(inst, child_params.merge({'iterator' => i.to_s}))
            end
          end
        else # this is a text node
          resolve_str(child, this_params)
        end
      end.flatten.compact
      resolved_node << new_children
    else
      @src_doc = get_doc doc_or_node
      @doc = Doc.new << resolve(src_doc.root, parent_params)
    end
  end

  attr_reader :e, :src_doc
  private


  def get_params(node, param_hash)
    if node.nodes.any? and !node.text? and node.nodes[0].name == 'duxml:parameters'
      local_params = {}
      params = node[0].nodes.clone
      params.each do |param|
        new_val = resolve_str(param[:value], param_hash)
        node[0].delete param unless new_val.parameterized?
        local_params[param[:name]] = new_val
      end
      node.delete node[0] unless node[0].nodes.any?
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
    output_str = content_str.clone
    questions = find_exprs content_str
    return output_str if questions.empty?
    questions.each do |question|
      reply = Macro.new e.evaluate(question, param_hash).to_s
      replacement_str = reply.parameterized? ? reply.macro_string : reply.demacro
      macro_string = Macro.new(question).macro_string
      output_str.gsub!(macro_string, replacement_str)
    end
    output_str
  end

  # @param str [String] string that may contain parameter expression e.g. 'asdf @(param + 2) asdf'
  # @return [Array[String]] array of macro strings e.g. 'asdf @(param + 2) asdf' => 'param + 2'
  def find_exprs(str)
    expressions = []
    str.scan('@(') do |c|
      expr_start_index = $~.offset(0)[0] # gets index of current match
      expr_end_index = find_close_parens_index str[expr_start_index+1..-1]
      expressions << str[expr_start_index+2, expr_end_index-1]
    end
    expressions
  end
end # module Dux

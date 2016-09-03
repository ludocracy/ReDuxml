# Copyright (c) 2016 Freescale Semiconductor Inc.
require File.expand_path(File.dirname(__FILE__) + '/ruby_ext/macro')
require File.expand_path(File.dirname(__FILE__) + '/re_duxml/evaluate')
require File.expand_path(File.dirname(__FILE__) + '/re_duxml/element')

module ReDuxml
  include Duxml

  class ResolverClass < ::Ox::Sax
    COND_ATTR_NAME = 'if'
    REF_ATTR_NAME = 'ref'

    @dead = false
    @cursor_stack

    attr_reader :e, :dead, :cursor_stack

    # @param doc [Ox::Document] document that is being constructed as XML is parsed
    # @param _observer [Object] object that will observe this document's content
    def initialize(logic)
      @cursor_stack = []
      @e = ReDuxml::Evaluator.new(logic)
    end

    def cursor
      @cursor_stack.last
    end

    def start_element(name)
      new_el = Duxml::Element.new(name, line, column)
      cursor << new_el unless cursor.nil?
      @cursor_stack << new_el
    end

    def attr(name, val)
      cursor[name] = val
    end

    def text(str)
      cursor << str
    end

    def end_element(name)
      case
        when cursor.if?
          cursor.remove_attribute(COND_ATTR_NAME)
        when cursor.respond_to?(:instantiate)
          # target = cursor.instantiate # target likely plural
          @cursor_stack[-2].replace(cursor, target)
        when cursor.ref?
          # target = resolve_ref
          @cursor_stack[-2].replace(cursor, target)
          cursor.remove_attribute(REF_ATTR_NAME)
        else
          @cursor_stack[-2].remove(cursor)
          return
      end
      @cursor_stack.pop
    end
  end

  # generates new doc from current doc, resolving parameter values and instantiating Instance objects, and pruning filtered objonents.
  def resolve(path=nil)
    io = File.open path
    saxer = ResolverClass.new(Duxml::Doc.new)
    Ox.sax_parse(saxer, io, {convert_special: true, symbolize: false})
    saxer.cursor
  end

  private

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

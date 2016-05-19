require_relative '../../ruby_ext/regexp'
require_relative '../../../lib/symbolic_ext/symbolic'

module Lexer
  @string_hash
  @input
  @tokens
  attr_reader :string_hash
  attr_accessor :input, :tokens

  TOKEN_TYPES = {
      string:   /STRING[\d]+/,
      function: /log|exp|sqrt/,
      bool:     /true|false/,
      param:    Regexp.identifier,
      num:      /\d/,
      grouping: /[\(\):,]/
  }

  Struct.new('Token', :type, :value)

  def lex(expr)
    @input = tag_strings(expr).split(/\b/).reverse.collect do |s| s.strip end
    @tokens = []
    while (sub_str = input.pop) do
      type = get_type sub_str
      value = formatted_value(sub_str, type)
      tokens << (@last_token = Struct::Token.new(type, value)) unless value.nil?
    end
    @last_token = nil
    tokens
  end # def lex(expr)

  private

  attr_reader :last_token

  def formatted_value(sub_str, type)
    formatted_str = untag_strings subst_minus(sub_str)
    case type
      when :operator, :grouping
        split_or_keep formatted_str
      when :param then get_var(formatted_str)
      when :num then formatted_str.to_i
      when :bool then formatted_str == 'true'
      else
        formatted_str
    end
  end

  def get_var(str)
    if(var_token = tokens.find do |t| t.value.to_s == str end)
      var_token.value
    else
      Symbolic.send(:var, name: str)
    end
  end

  def split_or_keep(str)
    if str.size > 1 && logic[str].nil?
      str.split(//).reverse.each do |c| input << c unless c.strip.empty? end
      nil
    else
      logic[str]
    end
  end

  def get_type(sub_str)
    TOKEN_TYPES.each do |type, regexp|
      return type if regexp.match(sub_str).to_s == sub_str
    end
    :operator
  end

  def subst_minus(_str)
    str = _str.dup
    if str == '-'
      unless last_token.nil? || last_token.type == 'operator' || %w(\( , :).include?(last_token.value)
        str = "\u2013"
        str.encode('utf-8')
      end
    end
    str
  end

  #
  def untag_strings(_expr)
    expr = _expr.dup
    string_hash.each do |k, v| expr.gsub!(k, v) end
    expr
  end

  #strings can contain whitespaces and characters the parser may miscategorize as operators, etc.
  # so they are replaced with unique keys in a module attribute hash for retrieval when doing string operations
  # and returning final result
  def tag_strings(expr)
    tagged_str = expr.dup
    @string_hash = {}
    expr.scan(Regexp.string) do |s|
      k = "STRING#{s.object_id}"
      tagged_str[s] = k
      @string_hash[k] = s
    end
    tagged_str
  end
end # module Lexer

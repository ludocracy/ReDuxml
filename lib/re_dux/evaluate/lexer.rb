require_relative '../../ruby_ext/regexp'

module Lexer
  @string_hash

  attr_reader :string_hash

  TOKEN_TYPES = {
      string:   /STRING[\d]+/,
      param:    Regexp.identifier,
      num:      /\d/,
      bool:     /true|false/,
      grouping: /[\(\):,]/
  }

  Struct.new('Token', :type, :value)

  def lex(expr)
    snippets = tag_strings(expr).split(/\b/).reverse.collect do |s| s.strip end
    tokens = []
    while (sub_str = snippets.pop) do
      t = :operator
      TOKEN_TYPES.each do |type, regexp|
        m = regexp.match(sub_str).to_s
        if regexp.match(sub_str).to_s == sub_str
          t = type
          break
        end
      end

      formatted_str = untag_strings subst_subtr(sub_str)
      if t == :operator && formatted_str.size > 1 && logic[formatted_str].nil?
        formatted_str.split(//).reverse.each do |c| snippets << c unless c.strip.empty? end
      else
        tokens << (@last_token = Struct::Token.new(t, formatted_str))
      end
    end
    @last_token = nil
    tokens
  end # def lex(expr)

  private

  attr_reader :last_token

  def subst_subtr(_str)
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

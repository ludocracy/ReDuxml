require_relative '../../ruby_ext/regexp'

module Lexer
  TOKEN_TYPES = {
      string:   /STRING[\d]+/,
      param:    Regexp.identifier,
      num:      /\d/,
      bool:     /true|false/
  }

  Struct.new('Token', :type, :value)

  private
  def tag_strings(expr)
    tagged_str = expr.dup
    string_hash = {}
    expr.scan(Regexp.string) do |s|
      k = "STRING#{s.object_id}"
      tagged_str[s] = k
      string_hash[k] = s
    end
    return string_hash, tagged_str
  end

  def lex(_expr)
    tokens = []
    string_hash, expr = tag_strings(_expr)
    expr.split(/\b/).each do |str|
      t = :operator
      TOKEN_TYPES.each do |type, regexp|
        if regexp.match(str)
          t = type
          break
        end
      end
      tokens << Struct::Token.new(t, str.strip)
    end
    tokens.collect do |t|
      t.value = string_hash[t.value] if t.type == :string
      t.freeze
    end
  end
end

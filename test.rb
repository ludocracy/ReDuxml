def test
  require_relative 'Editor'
  require_relative 'Builder'
  include Editor
  include Builder
  filename = 'sample_template.xml'
  file = File.open filename
  xml_doc = Nokogiri::XML file
  Editor.load xml_doc.root
  STDERR.puts "saving"
  File.write('output_' + filename, xml_doc.to_xml)
end

class Base
  def initialize
    @reserved = Array.new if @reserved.nil?
    @reserved << 'base'
  end
end

class Sub < Base
  def initialize
    @reserved = Array.new if @reserved.nil?
    @reserved << 'sub'
    super
  end
end
#copied below off internets - lets you do booleans with non-booleans
class String
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self.blank? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class Fixnum
  def to_bool
    return true if self == 1
    return false if self == 0
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class TrueClass
  def to_i; 1; end
  def to_bool; self; end
end

class FalseClass
  def to_i; 0; end
  def to_bool; self; end
end

class NilClass
  def to_bool; false; end
end
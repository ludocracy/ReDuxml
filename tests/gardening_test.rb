begin
  requires = %w(test/unit parser)
  relatives = %w(symbolic dentaku)
  includes = %w(Symbolic Dentaku)
  requires.each do |required|
    STDERR.puts "requiring #{required}"
    require required
  end
  relatives.each do |relative|
    STDERR.puts "requiring #{relative}"
    require_relative relative
  end
  includes.each do |included|
    STDERR.puts "including #{included}"
    include Module.const_get(included)
  end
end # includes, requires, etc
require 'test/unit'
require_relative 'console_test'
require 'parser'

class ConsoleTest < Test::Unit::TestCase
  include Dentaku
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
  end

  # tests main interface, opening, building and saving file
  # skipping DesignOS.rb for now
  def test_designos
    filename = 'sample_template.xml'
    file = File.open filename
    xml_doc = Nokogiri::XML file
    Editor.load xml_doc.root
    STDERR.puts "****saving to file."
    File.write('output_' + filename, xml_doc.to_xml)
    reference_xml_doc = Nokogiri::XML File.open 'reference_output_template.xml'
    assert xml_doc == reference_xml_doc, "****build failed!"
    STDERR.puts "****build passed!"
  end

  def teardown
  end
end


"#{
def test
end}"

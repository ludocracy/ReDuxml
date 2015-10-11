begin
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
end #includes, requires, etc


"#{
def test
  filename = 'sample_template.xml'
  file = File.open filename
  xml_doc = Nokogiri::XML file
  Editor.load xml_doc.root
  STDERR.puts "saving"
  File.write('output_' + filename, xml_doc.to_xml)
end}"

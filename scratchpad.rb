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


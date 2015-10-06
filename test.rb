module Test
  begin
  relatives = %w(dentaku/lib/dentaku)
  requires = %w()
  includes = %w(Dentaku)
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
   end#includes, requires, etc
  #***********START**************

  def self.start
    cleared = 5
    regression_tests = {}
    dev_tests = {}
    test_hash0=[
    ]

    test_hash=[
        "var" => "var",
        "2+2" =>  "4",
        "2*2" =>  "4",
        "var+2" =>  "var+2",
        "var*2" =>  "var*2",
        "var/2" =>  "var/2",
        "2+var" =>  "2+var",
        "2*var" =>  "2*var",
        "2/var" =>  "2/var",
        "4-2+var" =>  "2+var",
        "var+4-2" =>  "var+2",
        "var+var" =>  "var+var",
        "var*var" =>  "var*var",
        "var/var" =>  "var/var",
        "var*2-1" =>  "var*2-1",
        "var-2*1" =>  "var+-2",
        "2-1*var" =>  "2-1*var",
        "2-1/var" => "2-1/var",
        "var*2/1" =>  "var*2",
        "var/2-1" =>  "var/2-1",
        "2/1*var" =>  "2*var",
        "2/1-var" => "2-var",
        "var/2*4" => "var*2", #****************breaking from here
        "var*4/2" => "var*2",
        "var-2+var" =>  "var+-2+var",
        "var-2*var" =>  "var+-2*var",
        "var*2-var" =>  "var*2-var",
        "var/2+var" => "var/2+var",
        "var-2+4+var" =>  "var+2+var",
        "var-2*4*var" =>  "var+-8*var",
        #************************************************HIGH SCORE LINE******************************************************
        "var/2*4+var" =>  "var*2+var",
        "1+var/2*4+var" =>  "1+var*2+var"
    ]
    test_hash[0].each_with_index do |test, index|
      if index < cleared then regression_tests[test[0]] = test[1]
      else dev_tests[test[0]] = test[1]
      end
    end
    tests = (regression_tests.any? ? dev_tests.merge(regression_tests) : dev_tests)
    tests.each_with_index do |(key, value), index|
      result = Dentaku.evaluate(key, {}).to_s
      test_type = index < (tests.size-cleared) ? 'dev' : 'regression'
      STDERR.puts "  passed #{test_type} test #{index+1}: '#{key}'; answer is '#{value}'" if value == result
      STDERR.puts "\nFAILED #{test_type} test #{index+1}: '#{key}'; '#{result}' was incorrect; answer is '#{value}'" unless value == result
    end
  end
end

Test.start


#test_str = ("10 / 5 - var0**(2-4+7*x) >= 3 && !(var1 ? true : false || var2 != false)")

"#{
def test
  filename = 'sample_template.xml'
  file = File.open filename
  xml_doc = Nokogiri::XML file
  Editor.load xml_doc.root
  STDERR.puts "saving"
  File.write('output_' + filename, xml_doc.to_xml)
end}"

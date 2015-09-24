
module Debug
  #used to output debug messages wherever and whenever!!!
  def d str = ''
    context = caller[0]
    context[/.*\//] = ''
    begin
    location = root_name
    rescue NoMethodError
    location = self.class.to_s
    end
    STDERR.puts "#{context}: #{location} => #{str}"
  end
end
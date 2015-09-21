
module Debug
  #used to output debug messages wherever and whenever!!!
  def d str = ''
    context = caller[0]
    context[/.*\//] = ''
    location = root_name || self.class.to_s
    STDERR.puts "#{context}: #{location} => #{str}"
  end
end
require_relative 'object'
require_relative 'string'

def element *args
  raise ArgumentError unless args.first.identifier?
  name = args.first
  attrs = Hash.new
  content = ''
  if args.size == 3
    attrs &&= args[1]
    content &&= args[2]
  elsif args.last.is_a?(Hash)
    attrs = args.last
  elsif args.size == 2
    raise ArgumentError unless args.last.respond_to?(:to_s)
    content = args.last
  end
  e = "<#{name}>#{content}</#{name}>".xml
  attrs.each do |attr, val| e[attr]=val end unless attrs.nil?
  e
end
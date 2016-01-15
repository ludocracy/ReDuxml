require_relative 'object'
require_relative 'string'

def element *args
  raise ArgumentError unless args[0].identifier?
  name = args[0]
  raise ArgumentError unless args[1].nil? || args[1].is_a?(Hash)
  attrs = args[1] || {}
  raise ArgumentError unless args[2].nil? || args[2].respond_to?(:to_s)
  content = args[2] || ''

  e = "<#{name}>#{content}</#{name}>".xml
  attrs.each do |attr, val| e[attr]=val end
  e
end
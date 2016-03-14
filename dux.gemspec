# coding: utf-8
config = File.expand_path('../config', __FILE__)
require "#{config}/version"

Gem::Specification.new do |spec|
  spec.name          = "dux"
  spec.version       = DUX::VERSION
  spec.authors       = ["Peter Kong"]
  spec.email         = ["peter.kong@nxp.com"]
  spec.summary       = "Dynamic Universal XML"
  spec.homepage      = "http://www.github.com/ruby-dita/dux"

  #spec.required_ruby_version     = '>= 1.9.3'
  #spec.required_rubygems_version = '>= 1.8.11'

  # Only the files that are hit by these wildcards will be included in the
  # packaged gem, the default should hit everything in most cases but this will
  # need to be added to if you have any custom directories
  spec.files         = Dir["lib/**/*.rb", "lib/tasks/**/*.rake"
  ]
  spec.executables   = []
  spec.require_paths = ["lib"]

  # Add any gems that your plugin needs to run within a host application
  #spec.add_runtime_dependency "rgen_core", "~> 2.6"

  # Add any gems that your plugin needs for its development environment only
end
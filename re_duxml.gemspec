# coding: utf-8
Gem::Specification.new do |spec|
  spec.name          = "re_duxml"
  spec.version       = "0.1.2"
  spec.summary       = "Reusable Dynamic Universal XML"
  spec.authors       = ["Peter Kong"]
  spec.email         = ["peter.kong@nxp.com"]
  spec.homepage      = "http://www.github.com/re_duxml"
  spec.license       = "MIT"

  spec.required_ruby_version     = '>= 1.9.3'
  spec.required_rubygems_version = '>= 1.8.11'

  # Only the files that are hit by these wildcards will be included in the
  # packaged gem, the default should hit everything in most cases but this will
  # need to be added to if you have any custom directories
  spec.files         = Dir["java/**", "lib/**/*.rb", "xml/logic.xml"
  ]
  spec.executables   = []
  spec.require_paths = ["lib"]

  # Add any gems that your plugin needs to run within a host application
  spec.add_runtime_dependency "duxml", "~> 0.8.9"
  spec.add_runtime_dependency "con_duxml", "~> 0.4.0"
  spec.add_runtime_dependency "ast", "~> 2.2"
  spec.add_runtime_dependency "symbolic", "~> 0.3"

  # Add any gems that your plugin needs for its development environment only
end

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack-segment/version'

Gem::Specification.new do |s|
  s.name          = "rack-segment"
  s.version       = RackSegment::VERSION
  s.authors       = ["James Williamson"]
  s.email         = ["jwiliamson@gmail.com"]
  s.description   = %q{Segments traffic into buckets}
  s.summary       = %q{Segments traffic into buckets}
  s.homepage      = "https://github.com/jwilliamson/rack-segment"
  s.license       = "MIT"

  s.required_ruby_version = '>= 1.9.2'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  # s.add_dependency ''

  s.add_development_dependency 'bundler', '~> 1.3'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
end
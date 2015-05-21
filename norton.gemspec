# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'norton/version'

Gem::Specification.new do |spec|
  spec.name          = "norton"
  spec.version       = Norton::VERSION
  spec.authors       = ["Larry Zhao"]
  spec.email         = ["thehiddendepth@gmail.com"]
  spec.summary       = %q{Provide simple helpers on persist values in redis for performance. Works with ActiveRecord.}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "redis", "~> 3.1.0"
  spec.add_dependency "connection_pool", "~> 2.1.0"
  spec.add_dependency "activesupport", "~> 4.1"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest", "~> 5.5.1"
  spec.add_development_dependency "activerecord", "~> 4.1"
  spec.add_development_dependency "activerecord-nulldb-adapter"
end

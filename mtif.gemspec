# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mtif/version'

Gem::Specification.new do |spec|
  spec.name          = "mtif"
  spec.version       = MTIF::VERSION
  spec.authors       = ["Jim Meyer"]
  spec.email         = ["jim@geekdaily.org"]
  spec.summary       = %q{Read, parse, and write Movable Type Import Format files.}
  # spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = "https://geekdaily.org/projects/mtif"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
end

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailblazer/macro/contract/version'

Gem::Specification.new do |spec|
  spec.name          = "trailblazer-macro-contract"
  spec.version       = Trailblazer::Version::Macro::Contract::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = 'Operation macros for form objects'
  spec.summary       = 'Macros for form objects: Build, Validate, Persist'
  spec.homepage      = "http://trailblazer.to"
  spec.license       = "LGPL-3.0"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^test/})
  end
  spec.test_files    = `git ls-files -z test`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency "reform", ">= 2.2.0", "< 3.0.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "dry-validation"
  spec.add_development_dependency "reform-rails", "~> 0.2.0.rc2"
  spec.add_development_dependency "trailblazer-operation", ">= 0.6.2"
  spec.add_development_dependency "trailblazer-macro", ">= 2.1.5"
  spec.add_development_dependency "trailblazer-developer"
  spec.add_development_dependency "activemodel", "~> 6.0.0" # FIXME: we still don't support the Rails 6.1 errors object.

  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"

  spec.add_dependency "trailblazer-activity-dsl-linear", ">= 0.4.0", "< 0.5.0"

  spec.required_ruby_version = ">= 2.0.0"
end

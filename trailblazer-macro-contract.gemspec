lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailblazer/macro/contract/version'

Gem::Specification.new do |spec|
  spec.name          = "trailblazer-macro-contract"
  spec.version       = Trailblazer::Macro::Contract::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = 'Trailblazer operation form object specific macros'
  spec.summary       = 'Macros for form-objects: Build, Validate, Persist'
  spec.homepage      = "http://trailblazer.to"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^test/})
  end
  spec.test_files    = `git ls-files -z test`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency "reform", ">= 2.2.0", "< 3.0.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "trailblazer-macro", ">= 2.1.0.rc1", "< 2.2.0"
  spec.add_development_dependency "reform-rails"
  spec.add_development_dependency "dry-validation"

  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"

  spec.required_ruby_version = '>= 2.0.0'
end

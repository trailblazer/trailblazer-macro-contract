lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trailblazer/macro/contract/version'

Gem::Specification.new do |spec|
  spec.name          = "trailblazer-macro-contract"
  spec.version       = Trailblazer::Macro::Contract::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]
  spec.description   = 'Trailblazer operation macros to integrate Reform'
  spec.summary       = 'Trailblazer operation macros to integrate Reform forms and DRY.rb schemas.'
  spec.homepage      = "http://trailblazer.to"
  spec.license       = "LGPL-3.0"

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "declarative"
  spec.add_dependency "reform", ">= 2.2.0", "< 3.0.0"
  spec.add_dependency "trailblazer-operation", ">= 0.2.4", "< 0.3.0"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "trailblazer-macro", ">= 2.1.0.beta2", "< 2.2.0"

  spec.add_development_dependency "reform-rails"
  spec.add_development_dependency "dry-validation"
  spec.add_development_dependency "activemodel"

  spec.add_development_dependency "minitest"
  spec.add_development_dependency "nokogiri"
  spec.add_development_dependency "rake"

  spec.add_development_dependency "roar"
  spec.add_development_dependency "multi_json"

  spec.required_ruby_version = '>= 2.0.0'
end

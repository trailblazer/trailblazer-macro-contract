source 'https://rubygems.org'
# Specify your gem's dependencies in trailblazer.gemspec
gemspec

gem "dry-auto_inject"
gem "dry-matcher"
gem "dry-validation"

if ENV['USE_LOCAL_GEMS']
  gem "reform", path: "../reform"
  gem "reform-rails", path: "../reform-rails"
  gem "trailblazer-operation", path: "../trailblazer-operation"
  gem "trailblazer-macro", path: "../trailblazer-macro"
  gem "trailblazer-activity", path: "../trailblazer-activity"
  gem "trailblazer-context", path: "../trailblazer-context"
else
  gem "reform"
end

# gem "trailblazer-operation", github: "trailblazer/trailblazer-operation"
# gem "trailblazer-macro", github: "trailblazer/trailblazer-macro"

gem "minitest-line"

gem "rubocop", require: false

source "https://rubygems.org"

gemspec path: ".."

gem "activesupport", "~> 4.2", ">= 4.2.5"
gem "activerecord", "~> 4.2", ">= 4.2.5"

group :test do
  gem "simplecov", "~> 0.14", require: false
  gem "codeclimate-test-reporter", "~> 1.0", require: false
end

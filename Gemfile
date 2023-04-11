# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in datadome.gemspec
gemspec

group :local do
  # Guard
  gem "guard-rspec", require: false
  gem "terminal-notifier-guard", require: false # OS X
  gem "timecop"
end


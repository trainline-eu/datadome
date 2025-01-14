# Datadome

[![Gem Version](https://badge.fury.io/rb/datadome.svg)](https://badge.fury.io/rb/datadome) [![Build Status](https://travis-ci.org/shopmium/datadome.svg?branch=master)](https://travis-ci.org/shopmium/datadome)

Rack middleware for Datadome. https://datadome.co/

This is still an early version.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "datadome"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install datadome

## Usage with Rails

Create a `config/initializers/datadome.rb` file:

```ruby
require "datadome"

Datadome.configure do |config|
  # Set the Datadome API key
  config.api_key = "my-api-key"
  # or use an environment variable (better)
  # config.api_key = ENV["DATADOME_API_KEY"]

  # Choose the closest Datadome API endpoint
  # More info at https://docs.datadome.co/docs/api-server
  config.api_server = "api-us-east-1.datadome.co"

  # Add include matchers (optional)
  config.include_matchers << ->(request) { request.host == "www.my-domain.com" }

  # Add exclude matchers (optional)
  config.exclude_matchers << ->(request) { request.path =~ /\.(jpg|jpeg|png|gif)/i }
  
  # Bot request interception
  # A bot request is intercepted when monitor mode is false or when an intersept matcher returns true
  # Monitor mode : when set to true, incoming requests flagged as coming from a bot (useful for logging only) are not blocked
  # config.monitor_mode = true
  # Intercept matchers : when at least one of the matchers returns true, according bot request is intercepted. Allows specifying custom criteria from the env. Works with monitor mode enabled.
  # config.intercept_matchers << ->(env) { /Webapp/.match(env['HTTP_USER_AGENT'] }
  
  # Expose enriched headers
  # config.expose_headers = true
  # Enabling enriched headers will also expose the API response time. 
  
  # Configure http client timeouts (in seconds)
  # config.open_timeout = 1
  # config.timeout = 3
  
  # Configure non secure HTTP
  # config.use_https = true
end

Datadome.logger = Logger.new(STDOUT, level: :debug)

Rails.configuration.middleware.insert_after(ActionDispatch::RemoteIp, ::Datadome::Rack)
```

For the Javascript snippet, insert it directly in your layout file.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/shopmium/datadome.

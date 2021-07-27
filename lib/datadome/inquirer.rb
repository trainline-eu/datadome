# frozen_string_literal: true

require "rack"

module Datadome
  class Inquirer

    def initialize(env, exclude_matchers: nil, include_matchers: nil, monitor_mode: nil, expose_headers: nil)
      @env = env

      @monitor_mode = monitor_mode || Datadome.configuration.monitor_mode
      @expose_headers = expose_headers || Datadome.configuration.expose_headers
      @exclude_matchers = exclude_matchers || Datadome.configuration.exclude_matchers
      @include_matchers = include_matchers || Datadome.configuration.include_matchers
    end

    def build_response
      @validation_response.to_rack_response
    end

    def enriching
      status, headers, response = yield

      added_headers = ::Rack::Utils::HeaderHash.new(@validation_response.response_headers)

      headers = ::Rack::Utils::HeaderHash.new(headers)
      existing_set_cookie = headers["Set-Cookie"]

      headers.merge!(added_headers)

      if @expose_headers
        datadome_qualifying_headers = ::Rack::Utils::HeaderHash.new(
          @validation_response.request_headers.merge(datadome_response_time_header)
        )
        headers.merge!(datadome_qualifying_headers)
      end

      if added_headers["Set-Cookie"] && existing_set_cookie
        headers["Set-Cookie"] = merge_cookie(existing_set_cookie, added_headers["Set-Cookie"])
      end

      [status, headers, response]
    end

    def ignore?
      return false if include_matchers.empty? && exclude_matchers.empty?

      request = ::Rack::Request.new(@env)

      if include_matchers.any?
        any_include_matches =
          include_matchers.any? do |matcher|
            matcher.call(request.host, request.path)
          end

        return true unless any_include_matches
      end

      if exclude_matchers.any?
        any_exclude_matches =
          exclude_matchers.any? do |matcher|
            matcher.call(request.host, request.path)
          end

        return true if any_exclude_matches
      end

      false
    end

    def intercept?
      @monitor_mode == false && (@validation_response.pass == false || @validation_response.redirect)
    end

    def inquire
      inquiry_start_time = Time.now
      @validation_response = validate_request
      @inquiry_duration = Time.now - inquiry_start_time

      @validation_response
    end

    private

    attr_reader :exclude_matchers, :include_matchers

    def validate_request
      validation_request = ValidationRequest.from_env(@env)

      Datadome.logger.debug("Datadome: Validation Request: #{validation_request.inspect}")

      client = Client.new
      client.validate_request(validation_request.to_api_params).tap do |validation_response|
        Datadome.logger.debug("Datadome: Validation Response: #{validation_response.inspect}")
      end
    end

    def datadome_response_time_header
      response_time = if @validation_response&.timeout
        -1
      else
        @inquiry_duration
      end

      { "X-DataDomeResponseTime" => response_time }
    end

    def merge_cookie(old_cookie, cookie)
      case old_cookie
      when nil, ""
        cookie
      when String
        [old_cookie, cookie].join("\n")
      when Array
        (old_cookie + [cookie]).join("\n")
      end
    end

  end
end

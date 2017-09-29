# frozen_string_literal: true

require "rack"

module Datadome
  class Inquirer

    def initialize(env)
      @env = env
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

      if added_headers["Set-Cookie"] && existing_set_cookie
        headers["Set-Cookie"] = merge_cookie(existing_set_cookie, added_headers["Set-Cookie"])
      end

      [status, headers, response]
    end

    def intercept?
      @validation_response.pass == false || @validation_response.redirect
    end

    def inquire
      @validation_response = validate_request
    end

    private

    def validate_request
      validation_request = ValidationRequest.from_env(@env)

      Datadome.logger.debug("Datadome: Validation Request: #{validation_request.inspect}")

      client = Client.new
      client.validate_request(validation_request.to_api_params).tap do |validation_response|
        Datadome.logger.debug("Datadome: Validation Response: #{validation_response.inspect}")
      end
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

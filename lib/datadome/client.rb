# frozen_string_literal: true

require "faraday"
require "socket"

module Datadome
  class Client

    OPEN_TIMEOUT = 1
    TIMEOUT = 3

    class << self

      def base_url
        "https://#{Datadome.configuration.api_server}/"
      end

      def default_params
        {
          "Key" => Datadome.configuration.api_key,
          "RequestModuleName" => "DataDome Ruby Gem",
          "ModuleVersion" => ::Datadome::VERSION,
          "ServerName" => hostname,
        }
      end

      def hostname
        Socket.gethostname
      end

    end

    def check
      response =
        connection.get do |req|
          req.url("check")
        end

      response
    end

    def validate_request(data)
      data = data.merge(self.class.default_params)

      response =
        connection.post do |req|
          req.url("validate-request")
          req.headers["User-Agent"] = "DataDome"
          req.body = data
        end

      ValidationResponse.from_faraday_response(response)
    rescue Faraday::Error::ConnectionFailed, Faraday::Error::TimeoutError => e
      Datadome.logger.warn("Datadome: Timeout #{e}")

      ValidationResponse.pass
    end

    private

    def connection
      @connection ||=
        Faraday.new(url: self.class.base_url) do |faraday|
          faraday.request(:url_encoded)
          faraday.adapter(Faraday.default_adapter)
          faraday.options[:open_timeout] = OPEN_TIMEOUT
          faraday.options[:timeout] = TIMEOUT
        end
    end

  end
end

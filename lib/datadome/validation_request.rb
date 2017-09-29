# frozen_string_literal: true

module Datadome
  class ValidationRequest

    @definitions = []

    class << self

      attr_reader(:definitions)

      def limit_size(value, size:)
        if value && size
          value[0, size]
        else
          value
        end
      end

      def from_env(env)
        request = ::Rack::Request.new(env)

        new.tap do |validation_request|
          definitions.each do |definition|
            value = definition[:block].call(env, request)
            next if value.nil?

            validation_request[definition[:param_name]] = limit_size(value, size: definition[:max_size])
          end
        end
      end

      private

      def capture(param_name, max_size: nil, &block)
        definitions << {
          param_name: param_name,
          block: block,
          max_size: max_size,
        }
      end

    end

    capture("IP") do |_env, request|
      request.ip
    end

    capture("Port") do |_env, request|
      request.port
    end

    capture("Protocol") do |_env, request|
      request.scheme && request.scheme.upcase
    end

    capture("Method") do |_env, request|
      request.request_method
    end

    capture("Request", max_size: 2048) do |env, _request|
      env["ORIGINAL_FULLPATH"]
    end

    capture("TimeRequest") do |env, _request|
      usec_timestamp = (env["HTTP_X_REQUEST_START"] || "").gsub("t=", "").to_i
      usec_timestamp = (Time.now.to_f * 1_000_000).round if usec_timestamp.zero?

      usec_timestamp
    end

    capture("Accept", max_size: 512) do |env, _request|
      env["HTTP_ACCEPT"]
    end

    capture("AcceptCharset", max_size: 128) do |env, _request|
      env["HTTP_ACCEPT_CHARSET"]
    end

    capture("AcceptEncoding", max_size: 128) do |env, _request|
      env["HTTP_ACCEPT_ENCODING"]
    end

    capture("AcceptLanguage", max_size: 256) do |env, _request|
      env["HTTP_ACCEPT_LANGUAGE"]
    end

    capture("CacheControl") do |env, _request|
      env["HTTP_CACHE_CONTROL"]
    end

    capture("Connection") do |env, _request|
      env["HTTP_CONNECTION"]
    end

    capture("Host") do |_env, request|
      request.host
    end

    capture("Origin", max_size: 512) do |env, _request|
      env["HTTP_ORIGIN"]
    end

    capture("Pragma") do |env, _request|
      env["HTTP_PRAGMA"]
    end

    capture("Referer", max_size: 1024) do |env, _request|
      env["HTTP_REFERER"]
    end

    capture("UserAgent", max_size: 768) do |env, _request|
      env["HTTP_USER_AGENT"]
    end

    capture("XForwaredForIP", max_size: 512) do |env, _request|
      env["HTTP_X_FORWARDED_FOR"]
    end

    capture("X-Requested-With", max_size: 128) do |env, _request|
      env["HTTP_X_REQUESTED_WITH"]
    end

    capture("HeadersList", max_size: 512) do |env, _request|
      headers =
        env.keys
          .select { |key| key[0, 5] == "HTTP_" }
          .map { |key| key.gsub("HTTP_", "").downcase.tr("_", "-") }
      headers -= ["version"]

      headers.join(",")
    end

    capture("CookiesLen") do |env, _request|
      next(0) unless env["HTTP_COOKIE"]

      env["HTTP_COOKIE"].length
    end

    capture("PostParamLen") do |_env, request|
      (request.body || "").length
    end

    capture("AuthorizationLen") do |env, _request|
      next(0) unless env["HTTP_AUTHORIZATION"]

      env["HTTP_AUTHORIZATION"].length
    end

    capture("ClientID", max_size: 128) do |_env, request|
      request.cookies["datadome"]
    end

    def initialize
      @data = {}
    end

    def [](name)
      @data[name]
    end

    def []=(name, value)
      @data[name] = value
    end

    def to_api_params
      @data
    end

  end
end

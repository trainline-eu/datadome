# frozen_string_literal: true

module Datadome
  class ValidationResponse

    class << self

      def pass
        new(pass: true, redirect: false)
      end

      def from_faraday_response(response)
        validation_response =
          if response.status == 403
            new(pass: false, redirect: false, response_status: 403, response_body: response.body)
          elsif response.status == 301 || response.status == 302
            new(pass: false, redirect: true, response_status: response.status, redirection_location: response.headers["Location"])
          else
            pass
          end

        validation_response.request_headers["X-DataDomeResponse"] = response.headers["X-DataDomeResponse"]

        parse_headers_list(response.headers["X-DataDome-request-headers"]).each do |key|
          validation_response.request_headers[key] = response.headers[key]
        end

        parse_headers_list(response.headers["X-DataDome-headers"]).each do |key|
          validation_response.response_headers[key] = response.headers[key]
        end

        validation_response
      end

      def parse_headers_list(list)
        return [] if list.nil? || list == ""

        list.split(" ")
      end

    end

    attr_accessor :pass, :redirect
    attr_accessor :redirection_location, :request_headers, :response_body, :response_headers, :response_status

    def initialize(attrs = {})
      self.request_headers = {}
      self.response_headers = {}

      attrs.each do |key, value|
        public_send("#{key}=", value)
      end
    end

    def to_rack_response
      response = ::Rack::Response.new(@response_body || [], @response_status, @response_headers)
      response.redirect(@redirection_location, @response_status) if @redirect

      response.finish
    end

  end
end

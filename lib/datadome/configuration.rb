# frozen_string_literal: true

require "logger"

module Datadome
  class Configuration

    def initialize
      @api_server = "api.datadome.co"
      @exclude_matchers = []
      @include_matchers = []
      @monitor_mode = false
      @expose_headers = false
      @open_timeout = 1
      @timeout = 3
    end

    attr_accessor :api_key, :api_server, :exclude_matchers, :include_matchers, :monitor_mode, :expose_headers, :open_timeout, :timeout
  end
end

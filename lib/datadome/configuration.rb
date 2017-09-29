# frozen_string_literal: true

require "logger"

module Datadome
  class Configuration

    def initialize
      @api_server = "api.datadome.co"
    end

    attr_accessor :api_key, :api_server

  end
end

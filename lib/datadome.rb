# frozen_string_literal: true

require "datadome/version"
require "datadome/client"
require "datadome/configuration"
require "datadome/inquirer"
require "datadome/validation_request"
require "datadome/validation_response"
require "datadome/rack"

module Datadome

  class << self

    attr_writer :configuration

  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.logger
    @logger ||= Logger.new(STDOUT, level: :info)
  end

  def self.logger=(logger)
    @logger = logger
  end

end

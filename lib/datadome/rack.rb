# frozen_string_literal: true

require "rack"

module Datadome
  class Rack

    def initialize(app)
      @app = app
    end

    def call(env)
      inquirer = Inquirer.new(env)
      inquired = inquirer.inquire

      return @app.call(env) unless inquired

      if inquirer.intercept?
        inquirer.build_response
      else
        inquirer.enriching do
          @app.call(env)
        end
      end
    end

  end
end

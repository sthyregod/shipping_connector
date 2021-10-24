# frozen_string_literal: true

require 'active_support/core_ext/class/attribute'
require 'faraday'
require 'json'

module ShippingConnector
  class Carrier
    class_attribute :url

    def initialize(options = {})
      @options = options
      self.url = options[:mock_url] if options[:mock_url]
    end

    def require!(hash, *options)
      options.each do |option|
        raise ArgumentError, "Missing required parameter: #{option}" unless hash.key? option
      end
    end

    private

    # TODO: rescue HTTP error codes (or not?)
    def get(path, params)
      connection.get(path, params)
    end

    def connection
      Faraday.new url
    end
  end
end

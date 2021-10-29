# frozen_string_literal: true

module ShippingConnector
  class Shipment
    attr_reader :id, :receiver, :sender, :events, :status, :status_description

    def initialize(params = {})
      params.each { |key, value| instance_variable_set("@#{key}", value) }
    end

    class Event
      attr_reader :type, :time, :description, :location

      def initialize(params = {})
        params.each { |key, value| instance_variable_set("@#{key}", value) }
      end
    end
  end
end

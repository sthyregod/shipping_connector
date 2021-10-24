# frozen_string_literal: true

module ShippingConnector
  class ServicePoint
    attr_accessor :id, :name, :address, :zip_code, :city, :distance, :opening_hours

    def initialize(params = {})
      params.each { |key, value| instance_variable_set("@#{key}", value) }
    end

    class OpeningHours
      attr_accessor :monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday

      def initialize(params)
        params.each { |key, value| instance_variable_set("@#{key}", value) }
      end
    end
  end
end

# frozen_string_literal: true

module ShippingConnector
  class Dao < Carrier
    self.url = 'https://api.dao.as'

    # Initializes a new carrier object for DAO
    # @overload initialize(customer_id, password)
    #   @param customer_id [Integer] login details for the API user
    #   @param password [String] login details for the API user
    def initialize(options = {})
      require! options, :customer_id, :password
      super
    end

    # Returns a list of service points or a single service point. The returned distance is as the crow flies.
    # @overload service_points(scope, zip_code, address, limit = 10)
    #   @param scope [Symbol] the scope: `:list` for listing nearest service points
    #   @param zip_code [Integer, String] zip code for address to search from
    #   @param address [String] street address to search from
    #   @param limit [Integer] amount of service points to be returned
    #   @return [Array<ServicePoint>] the nearest service points ordered by distance
    # @overload service_points(id)
    #   @param id [Integer] the `id` of the service_point to be returned
    #   @return [ServicePoint] the service point for the given `id`
    def service_points(*arguments)
      scope   = arguments.slice!(0)
      options = arguments.slice!(0) || {}

      case scope
      when :list
        list_service_points(options)
      else
        find_service_point(scope)
      end
    end

    private

    def auth_params
      { kundeid: @options[:customer_id], kode: @options[:password] }
    end

    def find_service_point(id)

      service_point = get('/DAOPakkeshop/FindPakkeshop.php', { id: id })['pakkeshops'].first

      ServicePoint.new(id: service_point['shopId'], name: service_point['navn'],
                       address: service_point['adresse'], zip_code: service_point['postnr'],
                       city: service_point['bynavn'], opening_hours: opening_hours(service_point['aabningstider']))
    end

    def list_service_points(options)
      require! options, :zip_code, :address

      array = get('/DAOPakkeshop/FindPakkeshop.php',
                  {
                    postnr: options[:zip_code],
                    adresse: options[:address],
                    antal: options[:limit] || 10
                  })['pakkeshops']

      generate_service_points array
    end

    def get(path, params)
      response = super(path, params.merge(auth_params))
      body = JSON.parse response.body

      return body['resultat'] if body['status'] == 'OK'

      raise StandardError, "DAO errror ##{body['fejlkode']}: #{body['fejltekst']}"
    end

    def generate_service_points(array)
      result = []
      array.each do |service_point|
        result << ServicePoint.new(id: service_point['shopId'], name: service_point['navn'],
                                   address: service_point['adresse'], zip_code: service_point['postnr'],
                                   city: service_point['bynavn'], distance: service_point['afstand'],
                                   opening_hours: opening_hours(service_point['aabningstider']))
      end
      result
    end

    def opening_hours(args)
      hash = {}

      args.each do |weekday, hours|
        hash[weekdays[weekday]] = hours
      end

      ServicePoint::OpeningHours.new(hash)
    end

    def weekdays
      { 'man' => :monday, 'tir' => :tuesday, 'ons' => :wednesday, 'tor' => :thursday,
        'fre' => :friday, 'lor' => :saturday, 'son' => :sunday }
    end
  end
end

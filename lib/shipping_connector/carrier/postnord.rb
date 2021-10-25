# frozen_string_literal: true

module ShippingConnector
  class Postnord < Carrier
    self.url = 'api2.postnord.com'

    # Initializes a new carrier object for Postnord
    # @overload initialize(api_key)
    #   @param api_key [String] authentication details
    def initialize(options = {})
      require! options, :api_key
      super
    end

    # Returns a list of service points or a single service point. The returned distance is based on driving route.
    # @overload service_points(scope, zip_code, city, address, country, limit = 10)
    #   @param scope [Symbol] :list or :list_address to find by address
    #   @param zip_code [String] this or city is required
    #   @param city [String] this or zip_code is required
    #   @param address [String] street address to search from
    #   @param limit [String] amount of service points to be returned
    #   @return [Array<ServicePoint>] the nearest service points ordered by distance
    # @overload service_points(scope, latitude, longitude, limit = 10)
    #   @param scope [Symbol] :list_coordinates to find by coordinates
    #   @param latitude [String] required
    #   @param longitude [String] required
    #   @param limit [String] amount of service points to be returned
    #   @return [Array<ServicePoint>] the nearest service points ordered by distance
    # @overload service_points(id)
    #   @param id [Integer] the id of the service_point to be returned
    #   @return [ServicePoint] the service point for the given id
    def service_points(*arguments)
      scope   = arguments.slice!(0)
      options = arguments.slice!(0) || {}

      case scope
      when :list, :list_address
        require!(options, :country)
        list_service_points(options)
      when :list_coordinates
        require!(options, :country, :latitude, :longitude)
        list_by_coordinates(options)
      else
        require!(options, :country)
        find_service_point(scope, options)
      end
    end

    private

    def auth_params
      { apikey: @options[:api_key], returnType: 'json' }
    end

    def get(path, params)
      response = super(path, params.merge(auth_params))
      JSON.parse response.body
    rescue Faraday::ClientError => e
      body = JSON.parse e.response[:body]
      raise StandardError, "Postnord error: #{body['message']}"
    end

    def find_service_point(id, arguments)
      service_point = get('/rest/businesslocation/v5/servicepoints/ids',
                          {
                            ids: id, countryCode: arguments[:country]
                          })['servicePointInformationResponse']['servicePoints'].first

      ServicePoint.new(
        id: service_point['servicePointId'], zip_code: service_point['visitingAddress']['postalCode'],
        name: service_point['name'], city: service_point['visitingAddress']['city'],
        address: "#{service_point['visitingAddress']['streetName']} #{service_point['visitingAddress']['streetName']}",
        opening_hours: opening_hours(service_point['openingHours'])
      )
    end

    def list_service_points(options)
      unless options.key?(:city) || options.key?(:zip_code)
        raise ArgumentError, 'At least one of :city or :zip_code is required'
      end

      params = { countryCode: options[:country] }

      params[:city] = options[:city] if options[:city]
      params[:postalCode] = options[:postalCode] if options[:zip_code]
      params[:streetName] = options[:address] if options[:address]
      params[:numberOfServicePoints] = options[:limit] || 10

      array = get('/rest/businesslocation/v5/servicepoints/nearest/byaddress',
                  params)['servicePointInformationResponse']['servicePoints']

      generate_service_points array
    end

    def list_by_coordinates(options)
      array = get('/rest/businesslocation/v5/servicepoints/nearest/bycoordinates',
                  {
                    countryCode: options[:country],
                    northing: options[:latitude],
                    easting: options[:longitude],
                    numberOfServicePoints: options[:limit] || 10
                  })['servicePointInformationResponse']['servicePoints']

      generate_service_points array
    end

    def generate_service_points(array)
      result = []
      array.each do |service_point|
        result << ServicePoint.new(
          id: service_point['servicePointId'], zip_code: service_point['visitingAddress']['postalCode'],
          name: service_point['name'], city: service_point['visitingAddress']['city'],
          address: "#{service_point['visitingAddress']['streetName']} #{service_point['visitingAddress']['streetName']}",
          distance: service_point['routeDistance'], opening_hours: opening_hours(service_point['openingHours'])
)
      end
      result
    end

    def opening_hours(args)
      hash = {}

      args['postalServices'].each do |h|
        hash[h['openDay'].downcase.to_s] = "#{h['openTime']} - #{h['closeTime']}"
      end

      ServicePoint::OpeningHours.new(hash)
    end
  end
end

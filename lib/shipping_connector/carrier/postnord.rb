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

    # Returns a shipment with a list of events
    # @param id [String] the shipment id
    # @param locale [Symbol] two-letter language code, e.g. :da or :en
    # @return [Shipment] the shipment for the given id
    def shipment(id, locale: :en)
      # Ugh... Why is Postnord not consistent in their API...
      data = get('/rest/shipment/v5/trackandtrace/ids.json',
                 { id: id, locale: locale })

      shipment = data['shipments'].first { |s| s['shipmentId'] == id.to_s }
      raise "Shipment with ID #{id} not found" unless shipment

      item = shipment['items'].first { |i| i['itemId'] == id.to_s }
      raise "The shipment returned no items with ID #{id}" unless item

      generate_shipment(shipment['status'], item)
    end

    private

    def generate_shipment(status, item)
      events = generate_events(item['events'])
      Shipment.new(
        id: item['itemId'],
        events: events, status: convert_status(status),
        status_description: item['statusText']['header']
      )
    end

    def auth_params
      { apikey: @options[:api_key], returnType: 'json' }
    end

    def get(path, params)
      response = super(path, params.merge(auth_params))
      body = JSON.parse(response.body)
      return body.values.first if body.keys.first =~ /Response$/

      body
    rescue Faraday::ClientError => e
      body = JSON.parse e.response[:body]
      message = body.values.first['compositeFault']['faults'][0]
      raise StandardError, "Postnord error #{message['faultCode']}: #{message['explanationText']}"
    end

    def find_service_point(id, arguments)
      service_point = get('/rest/businesslocation/v5/servicepoints/ids',
                          {
                            ids: id, countryCode: arguments[:country]
                          })['servicePoints'].first

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
                  params)['servicePoints']

      generate_service_points array
    end

    def list_by_coordinates(options)
      array = get('/rest/businesslocation/v5/servicepoints/nearest/bycoordinates',
                  {
                    countryCode: options[:country],
                    northing: options[:latitude],
                    easting: options[:longitude],
                    numberOfServicePoints: options[:limit] || 10
                  })['servicePoints']

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

    def generate_events(events)
      array = []
      events.each do |event|
        array << Shipment::Event.new(
          type: convert_status(event['status']),
          time: convert_time(event['eventTime']),
          description: event['eventDescription'],
          location: event['location']['displayName']
        )
      end
      array
    end

    def convert_status(status)
      # FIXME: Find a good status category for 'OTHER'
      hash = {
        'DELIVERED' => :delivered,
        'EN_ROUTE' => :en_route,
        'AVAILABLE_FOR_DELIVERY' => :available_for_delivery
      }
      return hash[status] if hash[status]

      warn "Unknown status: #{status}"
      :unknown
    end

    def convert_time(time_string)
      TZInfo::Timezone.get('Europe/Copenhagen').to_local(Time.parse(time_string))
    end
  end
end

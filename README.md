# ShippingConnector
[![Gem Version](https://badge.fury.io/rb/shipping_connector.svg)](https://badge.fury.io/rb/shipping_connector) [![test](https://github.com/sthyregod/shipping_connector/actions/workflows/test.yml/badge.svg)](https://github.com/sthyregod/shipping_connector/actions/workflows/test.yml)

ShippingConnector is an abstraction library that makes connecting to various shipping
carriers' APIs easier. As with everything Ruby, the goal is to make writing code that
handles shipping logic fast and comfortable

## Installation

Add the following line to your Gemfile

```ruby
gem 'shipping_connector'
```

## Usage

Create a carrier object:

```ruby
# For Dao
carrier = ShippingConnector::Dao.new(customer_id: 'customerId', password: 'password')

# For Postnord
carrier = ShippingConnector::Postnord.new(api_key: 'abc12345')
```

Find nearest service points to a given address
```ruby
# Find service points
service_points = carrier.service_points(:list, zip_code: '7100', address: 'Niels Finsensvej 11')
service_points.first.id
# "1234"
service_points.first.name
# "Mediabox"
service_points.first.address
# "Bilka Vejle 20"
service_points.first.opening_hours.monday
# "08:00 - 22:00"

# Find service points by coordinates (Postnord exclusive)
service_points = postnord.service_points(:list_coordinates, 
                                         country: 'SE', 
                                         latitude: '59.338765', 
                                         longitude: '18.0263967')
```

Find service point from `id`:

```ruby
service_point = carrier.service_points(1234)
service_points.first.id
# "1234"
```

Get tracking information (only Postnord for now):

```ruby
shipment = carrier.shipment('96932007555SE')
shipment.id
# "96932007555SE"
shipment.status
# :delivered
shipment.events.first.time
# 2020-09-03 09:11:00 +0200
shipment.events.first.description
# "The shipment item will be delivered according to arrangement with the recipient"
```

## Changelog
[See CHANGELOG.md](CHANGELOG.md)

## Supported features
* [DAO](https://www.dao.as) - [DK] - [API docs](https://api.dao.as/docs/)
  * Nearest service points by address
  * Find service point by ID
* [PostNord](https://www.postnord.com) [SE, DK, FI, NO, DE] - [API docs](https://developer.postnord.com/)
  * Nearest service points by address
  * Nearest service points by coordinates
  * Find service point by ID
  * Get tracking information

**Notes**

The gem is currently very limited in features as focus lied in preparing the endpoints that was required for my work,
namely the search for service points for the listed carriers. The plan is to steadily add more endpoints and expand
the functionality to cover the most used features for several carriers while keeping the simplicity intact.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
Feel free to add a new carrier based on the current work at any time.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)

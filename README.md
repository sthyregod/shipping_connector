# ShippingConnector

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
carrier = ShippingConnector::Dao.new customer_id: 'customerId', password: 'password'
```

Find nearest service points to a given address
```ruby
service_points = carrier.service_points :list, zip_code: '7100', address: 'Niels Finsensvej 11'
service_points.first.id
# "1234"
service_points.first.name
# "Mediabox"
service_points.first.address
# "Bilka Vejle 20"
service_points.first.opening_hours.monday
# "08:00 - 22:00"
```

Find service point from `id`:

```ruby
service_point = carrier.service_points 1234
service_points.first.id
# "1234"
```

## Changelog
---

## Supported carriers
* [DAO](https://www.dao.as) - [DK]
  * [API docs](https://api.dao.as/docs/)
* [PostNord](https://www.postnord.com) [SE, DK, FI, NO, DE]
  * [API docs](https://developer.postnord.com/)

## Supported features
The gem is currently very limited in features as focus lied in preparing the endpoints that was required for my work,
namely the search for service points for the listed carriers. The plan is to steadily add more endpoints and expand
the functionality to cover the most used features for several carriers while keeping the simplicity intact.

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.
Feel free to add a new carrier based on the current work at any time.

Please make sure to update tests as appropriate.

## License
[MIT](https://choosealicense.com/licenses/mit/)
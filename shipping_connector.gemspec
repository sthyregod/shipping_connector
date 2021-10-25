# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name         = 'shipping_connector'
  s.version      = '0.1.0'
  s.summary      = 'A simple shipping_connector abstraction library'
  s.description  = <<-DESC
    ShippingConnector is an abstraction library that makes connecting to various shipping
    carriers' APIs easier. As with everything Ruby, the goal is to make writing code that
    handles shipping logic fast and comfortable
  DESC
  s.authors      = ['Simon Thyregod Kristensen']
  s.email        = 'git@simon.thyregod.eu'
  s.files        = Dir['lib/**/*']
  s.require_path = 'lib'
  s.homepage     = 'https://github.com/sthyregod/shipping_connector'
  s.license      = 'MIT'

  s.required_ruby_version = '>= 2.5'
end

# frozen_string_literal: true

require 'rspec'
require 'shipping_connector/carrier'
require 'shipping_connector/carrier/dao'
require 'shipping_connector/service_point'

describe 'Dao' do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:conn) { Faraday.new { |b| b.adapter(:test, stubs) } }
  let(:single_service_point) do
    {
      "status": 'OK',
      "fejlkode": '',
      "fejltekst": '',
      "resultat": {
        "pakkeshops": [
          {
            "shopId": '1234',
            "navn": 'Mediabox',
            "adresse": 'Bilka Vejle 20',
            "postnr": '7100',
            "bynavn": 'Vejle',
            "udsortering": 'E',
            "latitude": '55.7119',
            "longitude": '9.539939',
            "afstand": 2.652,
            "aabningstider": {
              "man": '08:00 - 22:00',
              "tir": '08:00 - 22:00',
              "ons": '08:00 - 22:00',
              "tor": '08:00 - 22:00',
              "fre": '08:00 - 24:00',
              "lor": '10:00 - 24:00',
              "son": '10:00 - 22:00'
            }
          }
        ],
        "udgangspunkt": {
          "latitude": '55.7255',
          "longtide": '9.57005'
        }
      }
    }.to_json
  end

  before do
    @dao = ShippingConnector::Dao.new(customer_id: 'customer_id', password: 'password')
    allow(@dao).to receive(:connection) { conn }
  end

  context 'when first parameter is :list' do
    it 'returns a service point object array' do
      stubs.get('/DAOPakkeshop/FindPakkeshop.php') do
        [
          200,
          { 'Content-Type': 'application/json' },
          single_service_point
        ]
      end
      service_points = @dao.service_points(:list, zip_code: '7100', address: 'Niels Finsensvej 11')
      expect(service_points.first&.id).to eq '1234'
      expect(service_points.first&.opening_hours&.monday).to eq '08:00 - 22:00'
    end
  end

  context 'when first parameter is an integer' do
    it 'returns a single servicep point' do
      stubs.get('/DAOPakkeshop/FindPakkeshop.php') do
        [
          200,
          { 'Content-Type': 'application/json' },
          single_service_point
        ]
      end

      service_point = @dao.service_points(1234)
      expect(service_point.id).to eq '1234'
      expect(service_point.opening_hours.monday).to eq '08:00 - 22:00'
    end
  end
end

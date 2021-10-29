# frozen_string_literal: true

require 'rspec'
require 'shipping_connector/carrier'
require 'shipping_connector/carrier/dao'
require 'shipping_connector/service_point'

describe 'Dao' do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:single_service_point) { File.read('spec/data/dao_list_service_points.json') }
  let(:dao) { ShippingConnector::Dao.new(customer_id: 'customer_id', password: 'password') }

  before do
    allow(dao).to receive(:connection) { Faraday.new { |b| b.adapter(:test, stubs) } }
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
      service_points = dao.service_points(:list, zip_code: '7100', address: 'Niels Finsensvej 11')
      expect(service_points.first&.id).to eq '1234'
    end
  end

  context 'when first parameter is an integer' do
    it 'returns a single servicepoint' do
      stubs.get('/DAOPakkeshop/FindPakkeshop.php') do
        [
          200,
          { 'Content-Type': 'application/json' },
          single_service_point
        ]
      end

      service_point = dao.service_points(1234)
      expect(service_point.id).to eq '1234'
    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'tzinfo'
require 'shipping_connector/carrier'
require 'shipping_connector/carrier/postnord'
require 'shipping_connector/service_point'
require 'shipping_connector/shipment'

describe 'Postnord' do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:service_points_by_address) { File.read('spec/data/postnord_list_by_address.json') }
  let(:service_points_by_coordinates) { File.read('spec/data/postnord_list_by_coordinates.json') }
  let(:service_points_by_id) { File.read('spec/data/postnord_find_by_id.json') }
  let(:postnord) { ShippingConnector::Postnord.new(api_key: 'api_key') }

  before do
    allow(postnord).to receive(:connection) { Faraday.new { |b| b.adapter(:test, stubs) } }
  end

  context 'when first parameter is :list' do
    it 'returns a service point object array based on address' do
      stubs.get('/rest/businesslocation/v5/servicepoints/nearest/byaddress') do
        [200, { 'Content-Type': 'application/json' }, service_points_by_address]
      end
      service_points = postnord.service_points(:list_address, zip_code: '33234', city: 'Gislaved',
                                                              country: 'SE', address: 'Holmengatan 14')
      expect(service_points.first&.id).to eq '376062'
    end
  end

  it 'returns a service point object array based on coordinates' do
    stubs.get('/rest/businesslocation/v5/servicepoints/nearest/bycoordinates') do
      [200, { 'Content-Type': 'application/json' }, service_points_by_coordinates]
    end
    service_points = postnord.service_points(:list_coordinates, country: 'SE',
                                                                latitude: '59.338765', longitude: '18.0263967')
    expect(service_points.first&.id).to eq '592977'
  end

  context 'when first parameter is an integer' do
    it 'returns a single service point' do
      stubs.get('/rest/businesslocation/v5/servicepoints/ids') do
        [200, { 'Content-Type': 'application/json' }, service_points_by_id]
      end
      service_point = postnord.service_points(376_062, country: 'SE')
      expect(service_point.id).to eq '376062'
    end
  end

  context 'when finding tracking events' do
    valid_tracking = File.read('spec/data/postnord_track_by_id.json')
    it 'returns events on valid tracking ID' do
      stubs.get('/rest/shipment/v5/trackandtrace/ids.json') do
        [200, { 'Content-Type': 'application/json' }, valid_tracking]
      end
      shipment = postnord.shipment('96932007555SE')
      expect(shipment.id).to eq '96932007555SE'
    end

    it 'fails on unknown tracking ID' do

    end
  end
end

# frozen_string_literal: true

require 'rspec'
require 'shipping_connector/service_point'

describe 'ServicePoint' do
  let(:opening_hours_params) do
    { monday: '08:00 - 22:00', tuesday: '08:00 - 22:00', wednesday: '08:00 - 22:00',
      thursday: '08:00 - 22:00', friday: '08:00 - 22:00' }
  end
  let(:opening_hours) { ShippingConnector::ServicePoint::OpeningHours.new opening_hours_params }
  let(:service_point_params) { { id: 1234, name: 'Name', address: 'Address 12', zip_code: '1000', distance: '2.523' } }

  it 'returns opening hours for a given day' do
    service_point = ShippingConnector::ServicePoint.new service_point_params
    service_point.opening_hours = opening_hours
    expect(service_point.opening_hours.monday).to eq opening_hours_params[:monday]
  end
end

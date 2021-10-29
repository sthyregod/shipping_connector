# frozen_string_literal: true

require 'rspec'
require 'shipping_connector/carrier'

describe 'Carrier' do
  let(:carrier) { ShippingConnector::Carrier.new }

  context 'when parameters are required' do
    it 'raises error with missing parameters' do
      expect { carrier.require!({ exists: true }, :exists, :does_not) }.to raise_error ArgumentError
    end
  end
end

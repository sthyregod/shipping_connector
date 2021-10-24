# frozen_string_literal: true

require 'rspec'
require 'shipping_connector/carrier'

describe 'Carrier' do
  before do
    @carrier = ShippingConnector::Carrier.new
  end

  after do
    # Do nothing
  end

  context 'when parameters are required' do
    it 'should raise' do
      expect { @carrier.require!({ exists: true }, :exists, :does_not) }.to raise_error ArgumentError
    end
  end
end

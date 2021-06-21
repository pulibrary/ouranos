# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Ouranos::Jobs::Deployment do
  subject(:deployment) { described_class.new(guid, data) }

  let(:guid) { 'guid' }
  let(:payload_name) do
    'payload_name'
  end
  let(:deployment_environment) do
    'deployment_environment'
  end
  let(:data) do
    {
      'deployment' => {
        'payload' => {
          'name' => payload_name
        },
        'environment' => deployment_environment
      }
    }
  end

  describe '.identifier' do
    let(:identifier) do
      described_class.identifier(guid, data)
    end

    context 'when the deployment data does not contain the payload name' do
      let(:data) do
        {
          'deployment' => {}
        }
      end

      it 'generates a lock key for redis using just the guid' do
        expect(identifier).to eq(guid)
      end
    end

    it 'generates the lock key from the deploymet information' do
      expect(identifier).to eq("#{payload_name}-#{deployment_environment}-deployment")
    end
  end

  describe '.perform' do
    let(:provider) do
      double
    end
    before do
      allow(provider).to receive(:run!)
      allow(Ouranos::Provider).to receive(:from).and_return(provider)

      described_class.perform(guid, data)
    end
    it 'constructs and runs a provider job from the GUID and deployment data' do
      expect(provider).to have_received(:run!)
    end
  end

  describe '.new' do
    it 'constructs the object using a GUID and data' do
      expect(deployment.guid).to eq(guid)
      expect(deployment.data).to eq(data)
    end
  end
end

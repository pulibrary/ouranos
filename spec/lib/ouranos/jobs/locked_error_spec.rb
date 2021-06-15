# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Ouranos::Jobs::LockedError do
  let(:payload_name) do
    'payload_name'
  end
  let(:payload) do
    {
      'name' => payload_name
    }
  end
  let(:guid) do
    'guid'
  end

  describe '.perform' do
    let(:logger) do
      instance_double(ActiveSupport::Logger)
    end
    let(:status) do
      instance_double(Deployment::Status)
    end
    let(:default_provider) do
      instance_double(Ouranos::Provider::DefaultProvider)
    end
    let(:description) do
      'Already deploying.'
    end

    before do
      allow(logger).to receive(:info)
      allow(Rails).to receive(:logger).and_return(logger)
      allow(status).to receive(:error!)
      allow(status).to receive(:description=)
      allow(default_provider).to receive(:status).and_return(status)
      allow(Ouranos::Provider::DefaultProvider).to receive(:new).and_return(default_provider)

      described_class.perform(guid, payload)
    end

    it 'raises the error and logs a warning' do
      expect(status).to have_received(:description=).with('Already deploying.')
      expect(status).to have_received(:error!)
      expect(logger).to have_received(:info).with('Deployment errored out, run was locked.')
    end
  end
end

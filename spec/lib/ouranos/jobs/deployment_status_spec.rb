# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Ouranos::Jobs::DeploymentStatus do
  let(:payload_name) do
    'payload_name'
  end
  let(:payload) do
    {
      'name' => payload_name
    }
  end

  describe '.perform' do
    let(:notifier) do
      double
    end

    before do
      allow(notifier).to receive(:post!)
      allow(Ouranos::Notifier).to receive(:for).and_return(notifier)

      described_class.perform(payload)
    end

    it 'transmits a POST request to the API for the notification' do
      expect(notifier).to have_received(:post!)
      expect(Ouranos::Notifier).to have_received(:for).with(payload)
    end
  end
end

# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Ouranos::Jobs::Status do
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
    let(:commit_status) do
      instance_double(CommitStatus)
    end

    before do
      allow(commit_status).to receive(:run!)
      allow(CommitStatus).to receive(:new).and_return(commit_status)

      described_class.perform(guid, payload)
    end

    it 'constructs and runs a new CommitStatus object' do
      expect(commit_status).to have_received(:run!)
    end
  end

  describe '.new' do
    let(:status) { described_class.new(guid, payload) }

    it 'constructs the Status object with the GUID and payload' do
      expect(status.guid).to eq(guid)
      expect(status.payload).to eq(payload)
    end
  end
end

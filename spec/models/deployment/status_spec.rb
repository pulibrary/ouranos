# frozen_string_literal: true
require 'rails_helper'

describe Deployment::Status, type: :model do
  subject(:status) { described_class.new(nwo, number) }

  let(:nwo) { 'nwo' }
  let(:number) { 'number' }
  let(:description) { "Deploying from Ouranos v1.0.0" }
  let(:client) { instance_double(Octokit::Client) }
  let(:output) { nil }

  before do
    allow(client).to receive(:create_deployment_status)
    allow(Octokit::Client).to receive(:new).and_return(client)
  end

  describe '.new' do
    it 'constructs a new object using the nwo and number' do
      expect(status.nwo).to eq(nwo)
      expect(status.number).to eq(number)
    end
  end

  describe '.deliveries' do
    before do
      allow(Ouranos).to receive(:testing?).and_return(true)
      status.pending!
    end

    after do
      allow(Ouranos).to receive(:testing?).and_return(false)
    end

    it 'accesses the delivery objects' do
      expect(described_class.deliveries).to be_an(Array)
      expect(described_class.deliveries.last).to be_a(Hash)
      expect(described_class.deliveries.last).to include(
        "description" => "Deploying from Ouranos v1.0.0",
        "status" => "pending"
      )
    end
  end

  describe '#url' do
    it 'generates the URL for the current deployment' do
      expect(status.url).to eq("https://api.github.com/repos/#{nwo}/deployments/#{number}")
    end
  end

  describe '#payload' do
    it 'constructs a Hash object' do
      status.output = output

      expect(status.payload).to eq(
        {
          "target_url" => output,
          "description" => description
        }
      )
    end
  end

  describe '#pending!' do
    let(:url) { "https://api.github.com/repos/#{nwo}/deployments/#{number}" }
    let(:payload) do
      {
        "target_url" => output,
        "description" => description
      }
    end

    it 'transmits an API request to update the status' do
      status.pending!

      expect(client).to have_received(:create_deployment_status).with(url, "pending", payload)
      expect(status.completed?).to be false
    end

    context 'when within the testing environment' do
      let(:payload) do
        {
          "target_url" => output,
          "description" => description,
          "status" => "pending"
        }
      end

      before do
        allow(Ouranos).to receive(:testing?).and_return(true)
      end

      it 'appends more delivery payloads' do
        status.pending!

        expect(described_class.deliveries).to include(payload)
      end
    end
  end

  describe '#success!' do
    let(:url) { "https://api.github.com/repos/#{nwo}/deployments/#{number}" }
    let(:payload) do
      {
        "target_url" => output,
        "description" => description
      }
    end

    it 'transmits an API request to update the status' do
      status.success!

      expect(client).to have_received(:create_deployment_status).with(url, "success", payload)
      expect(status.completed?).to be true
    end
  end

  describe '#failure!' do
    let(:url) { "https://api.github.com/repos/#{nwo}/deployments/#{number}" }
    let(:payload) do
      {
        "target_url" => output,
        "description" => description
      }
    end

    it 'transmits an API request to update the status' do
      status.failure!

      expect(client).to have_received(:create_deployment_status).with(url, "failure", payload)
      expect(status.completed?).to be true
    end
  end

  describe '#error!' do
    let(:url) { "https://api.github.com/repos/#{nwo}/deployments/#{number}" }
    let(:payload) do
      {
        "target_url" => output,
        "description" => description
      }
    end

    it 'transmits an API request to update the status' do
      status.error!

      expect(client).to have_received(:create_deployment_status).with(url, "error", payload)
      expect(status.completed?).to be true
    end
  end
end

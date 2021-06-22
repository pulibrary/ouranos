# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Jobs::EnvironmentLockedError do
  include DeploymentStatusMatchers, EnvironmentLockerMatchers

  describe ".perform" do
    let(:lock_params) do
      {
        name_with_owner: "atmos/heaven",
        environment: "production",
        actor: "atmos",
        deployment_id: "12345"
      }
    end
    let(:api_response) do
      {
        rels: []
      }
    end
    let(:api_response_json) do
      JSON.generate(api_response)
    end
    let(:deployment_status) { Deployment::Status.new("atmos/heaven", "12345") }

    before do
      allow(Ouranos).to receive(:testing?).and_return(true)

      stub_request(:get, "https://api.github.com/repos/atmos/heaven/deployments/12345").with(
        headers: {
          'Accept' => 'application/vnd.github.v3+json',
          'Authorization' => 'token <unknown>',
          'Content-Type' => 'application/json'
        }
      ).to_return(
        status: 200,
        headers: {
          'Content-Type' => 'application/json'
        },
        body: api_response_json
      )

      allow(Deployment::Status).to receive(:new).and_return(deployment_status)
      EnvironmentLocker.new(lock_params).lock!

      described_class.perform(lock_params)
    end

    after do
      allow(Ouranos).to receive(:testing?).and_call_original
    end

    it "triggers an error status with information about the lock" do
      expect(Deployment::Status).to have_received(:new).with("atmos/heaven", "12345")
      expect(Deployment::Status.deliveries).not_to be_empty
      expect(Deployment::Status.deliveries.first).to be_a(Hash)

      expect(Deployment::Status.deliveries.last).to include(
        "description" => "atmos/heaven is locked on production by atmos",
        "status" => "error"
      )
    end
  end
end

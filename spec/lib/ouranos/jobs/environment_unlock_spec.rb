# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Jobs::EnvironmentUnlock do
  include DeploymentStatusMatchers, EnvironmentLockerMatchers

  describe ".perform" do
    let(:name_with_owner) { "atmos/heaven" }
    let(:deployment_id) { "12345" }
    let(:lock_params) do
      {
        name_with_owner: name_with_owner,
        environment: "production",
        actor: "atmos",
        deployment_id: deployment_id
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
    let(:deployment_status) { Deployment::Status.new(name_with_owner, deployment_id) }

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

    it "unlocks the environment and sends a success status" do
      expect(Deployment::Status).to have_received(:new).with(name_with_owner, deployment_id)
      expect(Deployment::Status.deliveries).not_to be_empty
      expect(Deployment::Status.deliveries.first).to be_a(Hash)

      expect(Deployment::Status.deliveries.last).to include(
        "description" => "atmos/heaven unlocked on production by atmos",
        "status" => "success"
      )
    end
  end
end

# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Jobs::EnvironmentLock do
  include DeploymentStatusMatchers, EnvironmentLockerMatchers

  describe ".perform" do
    let(:name_with_owner) { "pulibrary/ouranos" }
    let(:lock_params) do
      {
        name_with_owner: name_with_owner,
        environment: "production",
        actor: "user",
        deployment_id: "12345"
      }
    end
    let(:response_body) do
      {
        rels: {
          statuses: {
            href: 'https://api.github.com/repos/pulibrary/ouranos/status'
          }
        }
      }
    end
    let(:request_body) do
      {
        target_url: nil,
        description: "pulibrary/ouranos locked on production by user",
        state: "success"
      }
    end
    let(:status) { instance_double(Deployment::Status) }

    before do
      stub_request(:post, "https://api.github.com/repos/pulibrary/ouranos/status").with(
        headers: {
          'Accept' => 'application/vnd.github.v3+json',
          'Authorization' => 'token <unknown>',
          'Content-Type' => 'application/json'
        },
        body: JSON.generate(request_body)
      ).to_return(status: 200)

      stub_request(:get, "https://api.github.com/repos/pulibrary/ouranos/deployments/12345").to_return(
        status: 200,
        headers: {
          'Content-Type' => 'application/json'
        },
        body: JSON.generate(response_body)
      )

      allow(status).to receive(:success!)
      allow(status).to receive(:description=)
      allow(Deployment::Status).to receive(:new).and_return(status)
    end

    it "locks the environment and sends a success status" do
      described_class.perform(lock_params)

      expect(Deployment::Status).to have_received(:new).with("pulibrary/ouranos", "12345")
      expect(status).to have_received(:description=).with('pulibrary/ouranos locked on production by user')
      expect(status).to have_received(:success!)
    end
  end
end

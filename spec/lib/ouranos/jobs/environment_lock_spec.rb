# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Jobs::EnvironmentLock do
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

    xit "locks the environment and sends a success status" do
      job = described_class

      job.perform(lock_params)

      expect("atmos/heaven-production").to be_locked
      expect(Deployment::Status).to have_event("status" => "success")
    end
  end
end

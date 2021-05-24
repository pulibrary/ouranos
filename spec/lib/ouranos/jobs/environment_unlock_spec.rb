# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Jobs::EnvironmentUnlock do
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

    before do
      EnvironmentLocker.new(lock_params).lock!
    end

    xit "unlocks the environment and sends a success status" do
      job = described_class

      job.perform(lock_params)

      expect("atmos/heaven-production").not_to be_locked
      expect(Deployment::Status).to have_event("status" => "success")
    end
  end
end

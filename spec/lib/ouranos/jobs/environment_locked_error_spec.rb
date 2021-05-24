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

    xit "triggers an error status with information about the lock" do
      job = described_class

      job.perform(lock_params)

      expect(Deployment::Status).to have_event(
        "status" => "error",
        "description" => "atmos/heaven is locked on production by Unknown"
      )

      EnvironmentLocker.new(lock_params).lock!

      job.perform(lock_params)

      expect(Deployment::Status).to have_event(
        "status" => "error",
        "description" => "atmos/heaven is locked on production by atmos"
      )
    end
  end
end

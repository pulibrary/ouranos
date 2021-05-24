# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Provider do
  include FixtureHelper

  describe ".from" do
    it "returns an initialized provider based on the payload config" do
      data = decoded_fixture_data("deployment")
      data["deployment"]["payload"]["config"]["provider"] = "capistrano"

      provider = described_class.from("1", data)

      expect(provider).to be_a(Ouranos::Provider::Capistrano)

      provider = described_class.from("1", {})

      expect(provider).to be_nil
    end
  end
end

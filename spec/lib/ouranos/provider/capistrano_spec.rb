# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Provider::Capistrano do
  include FixtureHelper

  let(:deployment) { described_class.new(SecureRandom.uuid, decoded_fixture_data("deployment-capistrano")) }

  it "finds deployment task" do
    expect(deployment.task).to eql "deploy:migrations"
  end
end

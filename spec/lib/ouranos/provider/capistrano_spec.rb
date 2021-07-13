# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Provider::Capistrano do
  include FixtureHelper

  let(:deployment) { described_class.new(SecureRandom.uuid, decoded_fixture_data("deployment-capistrano")) }

  it "finds deployment task" do
    expect(deployment.task).to eql "deploy:migrations"
  end

  describe '#cap_path' do
    it 'accesses the Capistrano executable path' do
      expect(deployment.cap_path).to eq('bin/cap')
    end
  end

  describe '#execute' do
    let(:last_child) do
      instance_double(POSIX::Spawn::Child)
    end

    before do
      allow(last_child).to receive(:out).and_return("".dup)
      allow(last_child).to receive(:err).and_return("".dup)
      allow(last_child).to receive(:success?).and_return(true)

      allow(POSIX::Spawn::Child).to receive(:new).and_return(last_child)

      deployment.execute
    end

    it 'clones the repository into the checkout directory' do
      expect(deployment.working_directory).not_to be_empty
      expect(File.exist?(deployment.working_directory)).to be true

      expect(POSIX::Spawn::Child).to have_received(:new).with(
        {
          "HOME" => deployment.working_directory
        },
        "/usr/bin/true",
        {}
      )
    end
  end
end

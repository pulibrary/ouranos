# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Provider::Capistrano do
  subject(:deployment) do
    described_class.new(
      guid,
      data
    )
  end

  let(:guid) { SecureRandom.uuid }
  let(:full_name) { 'full_name' }
  let(:clone_url) { 'https://github.com/pulibrary/ouranos.git' }
  let(:default_branch) { 'main' }
  let(:data) do
    {
      'deployment' => {
        'sha' => '438f8e543b4ca023b06ab9d4ffe1005038659357',
        'ref' => 'main',
        'payload' => {
          'config' => {
            'deploy_script' => 'deploy.sh'
          }
        }
      },
      'repository' => {
        'clone_url' => clone_url,
        'default_branch' => default_branch,
        'full_name' => full_name
      }
    }
  end

  it "finds deployment task" do
    expect(deployment.task).to eql "deploy"
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
    let(:github_token) { ENV["GITHUB_TOKEN"] }

    before do
      allow(last_child).to receive(:out).and_return("".dup)
      allow(last_child).to receive(:err).and_return("".dup)
      allow(last_child).to receive(:success?).and_return(true)
      allow(POSIX::Spawn::Child).to receive(:new).and_return(last_child)
      allow(Rails.logger).to receive(:info)

      FileUtils.mkdir(deployment.checkout_directory)
    end

    after do
      FileUtils.rm_rf(deployment.checkout_directory)
    end

    it 'clones the repository into the checkout directory' do
      deployment.execute

      expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Fetching the latest code")
      expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Executing capistrano: bin/cap  deploy")
    end
  end
end

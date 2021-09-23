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
    let(:deployment1) do
      described_class.new(
        guid,
        data
      )
    end

    before do
      allow(last_child).to receive(:out).and_return("".dup)
      allow(last_child).to receive(:err).and_return("".dup)
      allow(last_child).to receive(:success?).and_return(true)
      allow(POSIX::Spawn::Child).to receive(:new).and_return(last_child)
      allow(Rails.logger).to receive(:info)

      FileUtils.mkdir(deployment1.checkout_directory) unless File.exist?(deployment1.checkout_directory)
    end

    after do
      FileUtils.rm_rf(deployment1.checkout_directory)
    end

    it 'clones the repository into the checkout directory' do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(deployment1.checkout_directory).and_return(false)

      deployment1.execute

      expect(
        POSIX::Spawn::Child
      ).to have_received(:new).with({ "HOME" => deployment1.working_directory }, 'git', 'fetch', any_args)

      expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Fetching the latest code")
      expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Executing capistrano: bin/cap  deploy")
    end

    context 'when the checkout directory already exists' do
      before do
        FileUtils.mkdir(deployment.checkout_directory) unless File.exist?(deployment.checkout_directory)
      end

      after do
        FileUtils.rm_rf(deployment.checkout_directory)
      end

      it 'does not clone the git repository' do
        deployment.execute

        expect(POSIX::Spawn::Child).to have_received(:new).with({ "HOME" => deployment.working_directory }, 'git', 'fetch', {})
        expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Fetching the latest code").at_least(:once)
        expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Executing capistrano: bin/cap  deploy").at_least(:once)
      end
    end
  end
end

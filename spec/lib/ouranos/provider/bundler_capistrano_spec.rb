# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Provider::BundlerCapistrano do
  subject(:bundler_capistrano) { described_class.new(guid, payload) }

  let(:guid) { 'guid' }
  let(:full_name) { 'full_name' }
  let(:clone_url) { 'git://localhost.localdomain/invalid' }
  let(:default_branch) { 'default_branch' }
  let(:payload) do
    {
      'deployment' => {
        'sha' => '96ea9a5d7535027442ffcf974640fcc209c8fc95',
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

  describe '#execute' do
    let(:child) { instance_double(POSIX::Spawn::Child) }
    let(:logger) { instance_double(ActiveSupport::Logger) }
    let(:output) { "output" }
    let(:errors) { "errors" }

    before do
      allow(child).to receive(:err).and_return(errors.dup)
      allow(child).to receive(:out).and_return(output.dup)
      allow(child).to receive(:success?).and_return(true)
      allow(POSIX::Spawn::Child).to receive(:new).and_return(child)
    end

    after do
      FileUtils.rm_rf(bundler_capistrano.checkout_directory)
    end

    it 'fetches the code from Git using BASH commands' do
      allow(logger).to receive(:info)
      allow(Rails).to receive(:logger).and_return(logger)

      FileUtils.mkdir(bundler_capistrano.checkout_directory)
      bundler_capistrano

      script_path = File.join(bundler_capistrano.checkout_directory, 'deploy.sh')
      FileUtils.touch(script_path)
      FileUtils.chmod(0o755, script_path)

      gemfile_path = File.join(bundler_capistrano.checkout_directory, 'Gemfile')
      FileUtils.touch(gemfile_path)

      bundler_capistrano.execute

      expect(Rails.logger).to have_received(:info).with('full_name-guid: Fetching the latest code')
      expect(Rails.logger).to have_received(:info).with('full_name-guid: Executing bundler: bundle install --without ')
      expect(Rails.logger).to have_received(:info).with('full_name-guid: Executing capistrano: bundle exec cap  deploy')
    end
  end
end

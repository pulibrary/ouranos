# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Provider::BundlerCapistrano do
  subject(:deployment) { described_class.new(guid, data) }

  let(:guid) { 'guid' }
  let(:full_name) { 'full_name' }
  let(:clone_url) { 'git://localhost.localdomain/invalid' }
  let(:default_branch) { 'default_branch' }
  let(:data) do
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
    let(:bundle_definition) { instance_double(Bundler::Definition) }

    before do
      allow(bundle_definition).to receive(:groups).and_return([])
      allow(Bundler::Definition).to receive(:build).and_return(bundle_definition)

      allow(child).to receive(:err).and_return(errors.dup)
      allow(child).to receive(:out).and_return(output.dup)
      allow(child).to receive(:success?).and_return(true)
      allow(POSIX::Spawn::Child).to receive(:new).and_return(child)
    end

    after do
      FileUtils.rm_rf(deployment.checkout_directory)
    end

    it 'fetches the code from Git using BASH commands' do
      allow(logger).to receive(:info)
      allow(Rails).to receive(:logger).and_return(logger)

      FileUtils.mkdir(deployment.checkout_directory)
      deployment

      script_path = File.join(deployment.checkout_directory, 'deploy.sh')
      FileUtils.touch(script_path)
      FileUtils.chmod(0o755, script_path)

      gemfile_path = File.join(deployment.checkout_directory, 'Gemfile')
      FileUtils.touch(gemfile_path)

      deployment.execute

      expect(Rails.logger).to have_received(:info).with('full_name-guid: Fetching the latest code')
      expect(Rails.logger).to have_received(:info).with('full_name-guid: Executing bundler: bundle install --without ')
      expect(Rails.logger).to have_received(:info).with('full_name-guid: Executing capistrano: bundle exec cap  deploy')
    end

    context 'when the repository has not been cloned' do
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
        expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Executing bundler: bundle install --without ")
        expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Executing capistrano: bundle exec cap  deploy")
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
          expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Fetching the latest code")
          expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Executing bundler: bundle install --without ")
          expect(Rails.logger).to have_received(:info).with("full_name-#{guid}: Executing capistrano: bundle exec cap  deploy")
        end
      end
    end
  end
end

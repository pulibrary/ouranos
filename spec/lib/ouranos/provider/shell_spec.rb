# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Provider::Shell do
  subject(:shell) { described_class.new(guid, payload) }

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
    let(:working_directory) do
      "/tmp/dafa3da5507c2f35660e6473bd30386aa7573385"
    end
    let(:stderr_path) do
      "#{working_directory}/stderr.#{guid}.log"
    end
    let(:stdout_path) do
      "#{working_directory}/stdout.#{guid}.log"
    end
    let(:logger) { instance_double(ActiveSupport::Logger) }
    let(:checkout_directory) { "#{ENV['HOME']}/.pry_history" }
    let(:output) { "output" }
    let(:errors) { "errors" }

    before do
      allow(child).to receive(:err).and_return(errors.dup)
      allow(child).to receive(:out).and_return(output.dup)
      allow(child).to receive(:success?).and_return(true)
      allow(POSIX::Spawn::Child).to receive(:new).and_return(child)
    end

    after do
      FileUtils.rm_rf(shell.checkout_directory)
    end

    it 'fetches the code from Git using BASH commands' do
      allow(logger).to receive(:info)
      allow(Rails).to receive(:logger).and_return(logger)

      FileUtils.mkdir(shell.checkout_directory)
      shell

      script_path = File.join(shell.checkout_directory, 'deploy.sh')
      FileUtils.touch(script_path)
      FileUtils.chmod(0o755, script_path)

      shell.execute

      expect(Rails.logger).to have_received(:info).with('full_name-guid: Executing script: ./deploy.sh')
    end
  end
end

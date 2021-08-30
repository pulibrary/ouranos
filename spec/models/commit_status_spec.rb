# frozen_string_literal: true
require 'rails_helper'

describe CommitStatus do
  subject(:commit_status) do
    described_class.new(guid, data)
  end

  let(:guid) { 'guid' }
  let(:sha) { '00997d76f65cce0a63cdeeeac004ccfa904af174' }
  let(:state) { 'success' }
  let(:default_branch_name) { 'default_branch' }
  let(:default_branch) do
    {
      'name' => default_branch_name
    }
  end
  let(:branch1) do
    {
      'name' => 'branch1'
    }
  end
  let(:branches) do
    [
      default_branch,
      branch1
    ]
  end
  let(:full_name) { 'full_name' }
  let(:login) { 'login' }
  let(:data) do
    {
      'sha' => sha,
      'state' => state,
      'branches' => branches,
      'repository' => {
        'default_branch' => default_branch_name,
        'full_name' => full_name
      },
      'commit' => {
        'commit' => {
          'author' => {
            'login' => login
          }
        }
      }
    }
  end

  describe '#successful?' do
    it 'determines if the payload state was successful' do
      expect(commit_status.successful?).to be true
    end
  end

  describe '#sha' do
    it 'accesses the SHA hash for the commit' do
      expect(commit_status.sha).to eq('00997d76')
    end
  end

  describe '#state' do
    it 'accesses the state for the commit status' do
      expect(commit_status.state).to eq(state)
    end
  end

  describe '#branches' do
    it 'accesses the branches for the repository' do
      expect(commit_status.branches).to eq(branches)
    end
  end

  describe '#default_branch' do
    it 'accesses the default branch for the repository' do
      expect(commit_status.default_branch).to eq(default_branch_name)
    end
  end

  describe '#default_branch?' do
    it 'determines if the default branch is available within the repository branches' do
      expect(commit_status.default_branch?).to be true
    end
  end

  describe '#name_with_owner' do
    it 'the full name associated with the repository' do
      expect(commit_status.name_with_owner).to eq(full_name)
    end
  end

  describe '#author' do
    it 'accesses the author associated with the commit' do
      expect(commit_status.author).to eq(login)
    end
  end

  describe '#run!' do
    let(:state) { 'success' }
    let(:logger) { instance_double(ActiveSupport::Logger) }
    let(:auto_deployment) do
      instance_double(AutoDeployment)
    end
    let(:deployment) do
      instance_double(Deployment)
    end
    let(:deployments) do
      [
        deployment
      ]
    end

    before do
      allow(logger).to receive(:info)
      allow(Rails).to receive(:logger).and_return(logger)
      allow(auto_deployment).to receive(:execute)
      allow(AutoDeployment).to receive(:new).and_return(auto_deployment)
      allow(deployment).to receive(:environment).and_return('production')
      allow(Deployment).to receive(:latest_for_name_with_owner).with(full_name).and_return(deployments)
    end

    context 'when using an alternate default branch' do
      let(:default_branch_name) { 'alternate_branch' }

      it 'logs a message' do
        commit_status.run!

        expect(logger).to have_received(:info).with("trying to deploy full_name@00997d76 to production")
      end
    end

    context 'when the commit is not successful' do
      let(:state) { 'failure' }

      before do
        allow(AutoDeployment).to receive(:new)
      end

      it 'does not execute a new deployment' do
        commit_status.run!

        expect(logger).not_to have_received(:info)
        expect(AutoDeployment).not_to have_received(:new)
      end
    end

    context 'when the select branch is not the default branch' do
      let(:default_branch_name) { 'branch2' }

      let(:default_branch) do
        {
          'name' => 'default_branch'
        }
      end

      before do
        allow(Rails.logger).to receive(:info)
        commit_status.run!
      end

      it 'does not deploy the branch and logs a message' do
        expect(Rails.logger).to have_received(:info).with('Ignoring commit status(success) for full_name+default_branch@00997d76')
      end
    end

    it 'executes a new auto. deployment' do
      commit_status.run!

      expect(logger).to have_received(:info).with("trying to deploy full_name@00997d76 to production")
      expect(auto_deployment).to have_received(:execute)
    end
  end
end

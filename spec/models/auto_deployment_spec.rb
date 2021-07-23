# frozen_string_literal: true
require 'rails_helper'

describe AutoDeployment, type: :model do
  subject(:auto_deployment) { described_class.new(deployment, commit_status) }

  let(:deployment) { instance_double(Deployment) }
  let(:commit_status) { instance_double(CommitStatus) }

  let(:api_response_repository_disabled) do
    {
      id: 369_641_778,
      node_id: "MDEwOlJlcG9zaXRvcnkzNjk2NDE3Nzg=",
      name: "heaven",
      full_name: "atmos/heaven",
      private: false,
      owner: {},
      html_url: "https://github.com/atmos/heaven",
      description: "A Capistrano-driven deployment service build using https://github.com/atmos/heaven.",
      fork: false
    }
  end

  let(:sha) { "1c66a7a6d0c9055f8de26b9aabeb5d8b9d233146" }
  let(:author) { "atmos" }

  let(:api_response_statuses) do
    [
      {
        url: "https://api.github.com/repos/atmos/heaven/statuses/1c66a7a6d0c9055f8de26b9aabeb5d8b9d233146",
        avatar_url: "https://avatars.githubusercontent.com/oa/4808?v=4",
        id: 13_587_391_075,
        node_id: "MDEzOlN0YXR1c0NvbnRleHQxMzU4NzM5MTA3NQ==",
        state: "success",
        description: "Your tests passed on CircleCI!",
        target_url: "https://circleci.com/gh/atmos/heaven/168?utm_campaign=vcs-integration-link&utm_medium=referral&utm_source=github-build-link",
        context: "ci/circleci: lint",
        created_at: "2021-06-28T15:01:49Z",
        updated_at: "2021-06-28T15:01:49Z"
      }
    ]
  end
  let(:api_response) do
    {
      state: "success",
      statuses: api_response_statuses,
      sha: sha,
      total_count: 3,
      repository: {},
      commit_url: "https://api.github.com/repos/pulibrary/ouranos/commits/1c66a7a6d0c9055f8de26b9aabeb5d8b9d233146",
      url: "https://api.github.com/repos/pulibrary/ouranos/commits/1c66a7a6d0c9055f8de26b9aabeb5d8b9d233146/status"
    }
  end
  let(:api_response_json) do
    JSON.generate(api_response)
  end

  before do
    allow(commit_status).to receive(:author) { author }
    allow(commit_status).to receive(:name_with_owner) { "atmos/heaven" }
    allow(commit_status).to receive(:sha) { sha }

    stub_request(:get, "https://api.github.com/repos/atmos/heaven/commits/1c66a7a6d0c9055f8de26b9aabeb5d8b9d233146/status").with(
      headers: {
        'Accept' => 'application/vnd.github.v3+json',
        'Authorization' => 'token <unknown>',
        'Content-Type' => 'application/json'
      }
    ).to_return(
      status: 200,
      headers: {
        'Content-Type' => 'application/json'
      },
      body: api_response_json
    )

    allow(deployment).to receive(:auto_deploy_payload)
  end

  describe '#combined_status_green?' do
    it 'determines if the all deployments were successful' do
      expect(auto_deployment.combined_status_green?).to be true
    end
  end

  describe '#aggregate' do
    it 'accesses the combined status of all deployments' do
      expect(auto_deployment.aggregate).not_to be nil
      expect(auto_deployment.aggregate.to_h).to eq(api_response)
    end
  end

  describe '#updated_payload' do
    before do
      auto_deployment.updated_payload
    end

    it 'transmits a payload update using a PATCH request' do
      expect(deployment).to have_received(:auto_deploy_payload).with(author, sha)
    end
  end

  describe '#compare' do
    xit 'derives a comparison between the base deployment and the latest commit' do
    end
  end

  describe '#ahead?' do
    xit 'determines if the base deployment is ahead of the latest commit' do
    end
  end

  describe '#create_deployment' do
    xit 'transmits a new payload using a POST request' do
    end
  end

  describe '#execute' do
    xit 'creates a new deployment' do
    end

    context 'when the current deployment statuses are not all successes' do
      xit 'does not create a new deployment' do
      end
    end

    context 'when the current deployment is behind the latest commit' do
      xit 'does not create a new deployment and logs a message' do
      end
    end
  end
end

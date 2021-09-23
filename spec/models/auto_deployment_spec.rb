# frozen_string_literal: true
require 'rails_helper'

describe AutoDeployment do
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
  let(:state) { "success" }
  let(:api_response_statuses) do
    [
      {
        url: "https://api.github.com/repos/atmos/heaven/statuses/1c66a7a6d0c9055f8de26b9aabeb5d8b9d233146",
        avatar_url: "https://avatars.githubusercontent.com/oa/4808?v=4",
        id: 13_587_391_075,
        node_id: "MDEzOlN0YXR1c0NvbnRleHQxMzU4NzM5MTA3NQ==",
        state: state,
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
      state: state,
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

  let(:ahead_by) { 1 }
  let(:sha2) { sha }
  let(:api_compare_response) do
    {
      url: "https://api.github.com/repos/atmos/heaven/compare/#{sha}...#{sha2}",
      html_url: "https://api.github.com/repos/atmos/heaven/compare/#{sha}...#{sha2}",
      permalink_url: "https://api.github.com/atmos/heaven/compare/atmos:#{sha[0..6]}...atmos:#{sha2[0..6]}",
      diff_url: "https://api.github.com/repos/atmos/heaven/compare/#{sha}...#{sha2}.diff",
      patch_url: "https://api.github.com/repos/atmos/heaven/compare/#{sha}...#{sha2}.patch",
      base_commit: {},
      merge_base_commit: {},
      status: "ahead",
      ahead_by: ahead_by,
      behind_by: 0,
      total_commits: 1,
      commits: [],
      files: []
    }
  end
  let(:api_compare_response_json) do
    JSON.generate(api_compare_response)
  end

  before do
    allow(commit_status).to receive(:author) { author }
    allow(commit_status).to receive(:name_with_owner) { "atmos/heaven" }
    allow(commit_status).to receive(:sha) { sha }

    stub_request(:get, "https://api.github.com/repos/atmos/heaven/commits/#{sha}/status").with(
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

    stub_request(:get, "https://api.github.com/repos/atmos/heaven/compare/#{sha}...#{sha2}").with(
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
      body: api_compare_response_json
    )

    allow(deployment).to receive(:sha).and_return(sha)

    allow(deployment).to receive(:environment).and_return('production')
    stub_request(:post, "https://api.github.com/repos/atmos/heaven/deployments").with(
      body: api_deployment_request_json,
      headers: {
        'Accept' => 'application/vnd.github.v3+json',
        'Authorization' => 'token <unknown>',
        'Content-Type' => 'application/json'
      }
    ).to_return(
      status: 200
    )
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
    let(:compared) { auto_deployment.compare.to_h }

    it 'derives a comparison between the base deployment and the latest commit' do
      expect(compared).to be_a(Hash)

      expect(compared).to include(
        url: "https://api.github.com/repos/atmos/heaven/compare/#{sha}...#{sha2}",
        html_url: "https://api.github.com/repos/atmos/heaven/compare/#{sha}...#{sha2}",
        permalink_url: "https://api.github.com/atmos/heaven/compare/atmos:#{sha[0..6]}...atmos:#{sha2[0..6]}",
        diff_url: "https://api.github.com/repos/atmos/heaven/compare/#{sha}...#{sha2}.diff",
        patch_url: "https://api.github.com/repos/atmos/heaven/compare/#{sha}...#{sha2}.patch"
      )
    end
  end

  describe '#ahead?' do
    it 'determines if the base deployment is ahead of the latest commit' do
      expect(auto_deployment.ahead?).to be true
    end
  end

  let(:api_deployment_request) do
    {
      payload: nil,
      environment: 'production',
      description: 'Heaven auto deploy triggered by a commit status change',
      ref: sha
    }
  end

  let(:api_deployment_request_json) do
    JSON.generate(api_deployment_request)
  end

  describe '#create_deployment' do
    it 'transmits a new payload using a POST request' do
      auto_deployment.create_deployment

      expect(a_request(:post, "https://api.github.com/repos/atmos/heaven/deployments").with { |req| req.body == api_deployment_request_json }).to have_been_made
    end
  end

  describe '#execute' do
    let(:logger) do
      instance_double(ActiveSupport::Logger)
    end

    before do
      allow(commit_status).to receive(:default_branch).and_return('main')

      allow(logger).to receive(:info)
      allow(Rails).to receive(:logger).and_return(logger)

      auto_deployment.execute
    end

    it 'creates a new deployment' do
      expect(logger).to have_received(:info).with("Trying to deploy #{sha}")
      expect(a_request(:post, "https://api.github.com/repos/atmos/heaven/deployments").with { |req| req.body == api_deployment_request_json }).to have_been_made
    end

    context 'when the current deployment statuses are not all successes' do
      let(:state) { "failure" }
      let(:sha2) { sha }

      it 'does not create a new deployment' do
        expect(a_request(:post, "https://api.github.com/repos/atmos/heaven/deployments").with { |req| req.body == api_deployment_request_json }).not_to have_been_made
      end
    end

    context 'when the current deployment is behind the latest commit' do
      let(:ahead_by) { 0 }
      let(:sha2) { sha }

      it 'does not create a new deployment and logs a message' do
        expect(logger).to have_received(:info).with("#{sha} isn't ahead of #{sha2} and in the main")

        expect(a_request(:post, "https://api.github.com/repos/atmos/heaven/deployments").with { |req| req.body == api_deployment_request_json }).not_to have_been_made
      end
    end
  end
end

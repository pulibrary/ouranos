# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Provider::DefaultProvider do
  subject(:default_provider) { described_class.new(guid, payload) }

  let(:valid_git_ref) { Ouranos::Provider::DefaultProvider::VALID_GIT_REF }
  let(:guid) { 'guid' }
  let(:full_name) { 'full_name' }
  let(:owner) { 'owner' }
  let(:clone_url) { 'git://localhost.localdomain/invalid' }
  let(:default_branch) { 'default_branch' }
  let(:sha) { '96ea9a5d7535027442ffcf974640fcc209c8fc95' }
  let(:ref) { 'main' }
  let(:deployment_id) { 'test-id' }
  let(:environment) { 'production' }
  let(:payload) do
    {
      'deployment' => {
        'id' => deployment_id,
        'environment' => environment,
        'sha' => sha,
        'ref' => ref,
        'payload' => {
          'config' => {
            'deploy_script' => 'deploy.sh'
          }
        }
      },
      'repository' => {
        'clone_url' => clone_url,
        'default_branch' => default_branch,
        'full_name' => full_name,
        'owner' => owner
      }
    }
  end
  let(:time) { Time.zone.local(1990) }

  before do
    Timecop.freeze(time)
  end

  after do
    Timecop.return
  end

  describe "#run!" do
    let(:gist_response) do
      {
        id: 'gist-id',
        html_url: 'https://github.com/pulibrary/ouranos'
      }
    end
    let(:status_request) do
      {
        target_url: nil,
        description: "pulibrary/ouranos locked on production by user",
        state: "success"
      }
    end
    let(:deployment_response) do
      {
        rels: {
          statuses: {
            href: 'https://api.github.com/repos/pulibrary/ouranos/status'
          }
        }
      }
    end
    let(:last_child) do
      instance_double(POSIX::Spawn::Child)
    end

    before do
      stub_request(:patch, "https://api.github.com/gists/gist-id")
        .with(
          body: "{\"files\":{},\"public\":false}",
          headers: {
            'Accept' => 'application/vnd.github.v3+json',
            'Authorization' => 'token <unknown>',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
            status: 200,
            headers: {},
            body: ""
          )

      # Pending
      stub_request(:post, "https://api.github.com/repos/pulibrary/ouranos/status")
        .with(
          body: "{\"target_url\":\"https://github.com/pulibrary/ouranos\",\"description\":\"Deploying from Ouranos v1.0.0\",\"state\":\"pending\"}",
          headers: {
            'Accept' => 'application/vnd.github.v3+json',
            'Authorization' => 'token <unknown>',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'application/json'
            },
            body: JSON.generate(status_request)
          )
      # Failure
      stub_request(:post, "https://api.github.com/repos/pulibrary/ouranos/status")
        .with(
          body: "{\"target_url\":\"https://github.com/pulibrary/ouranos\",\"description\":\"Deploying from Ouranos v1.0.0\",\"state\":\"failure\"}",
          headers: {
            'Accept' => 'application/vnd.github.v3+json',
            'Authorization' => 'token <unknown>',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'application/json'
            },
            body: JSON.generate(status_request)
          )
      stub_request(:get, "https://api.github.com/repos/full_name/deployments/test-id")
        .with(
          headers: {
            'Accept' => 'application/vnd.github.v3+json',
            'Authorization' => 'token <unknown>',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'application/json'
            },
            body: JSON.generate(deployment_response)
          )

      stub_request(:patch, "https://api.github.com/gists/gist-id")
        .with(
          body: "{\"files\":{},\"public\":false}",
          headers: {
            'Accept' => 'application/vnd.github.v3+json',
            'Authorization' => 'token <unknown>',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
            status: 200,
            headers: {
              'Content-Type' => 'application/json'
            },
            body: "{}"
          )

      stub_request(:post, "https://api.github.com/gists")
        .with(
          body: "{\"files\":{\"stdout\":{\"content\":\"Deployment test-id pending\"}},\"public\":false,\"description\":\"Ouranos number test-id for full_name\"}",
          headers: {
            'Accept' => 'application/vnd.github.v3+json',
            'Authorization' => 'token <unknown>',
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
            headers: {
              'Content-Type' => 'application/json'
            },
            status: 200,
            body: JSON.generate(gist_response)
          )

      default_provider.run!
    end

    it 'runs the provider' do
      expect(Deployment.all).not_to be_empty
      expect(Deployment.last.custom_payload).to eq(
        JSON.generate('config' => {
                        'deploy_script' => 'deploy.sh'
                      })
      )
      expect(Deployment.last.environment).to eq(environment)
      expect(Deployment.last.guid).to eq(guid)
      expect(Deployment.last.name).to eq(full_name)
      expect(Deployment.last.name_with_owner).to eq(full_name)
      expect(Deployment.last.output).to eq("https://github.com/pulibrary/ouranos")
      expect(Deployment.last.ref).to eq(ref)
      expect(Deployment.last.sha).to eq("96ea9a5d")
    end
  end

  describe "#deployment_time_elapsed" do
    it 'accesses the time which has elapsed from the starting the deployment' do
      expect(default_provider.deployment_time_elapsed).to eq(0)
    end
  end

  describe "#deployment_time_remaining" do
    it 'accesses the time remaining for the deployment' do
      expect(default_provider.deployment_time_remaining).to eq(300)
    end
  end

  describe "#deployment_start_time" do
    it 'accesses the starting time for the deployment' do
      expect(default_provider.deployment_start_time).to eq(time)
    end
  end

  describe "#start_deployment_timeout!" do
    it 'accesses the timeout period for starting the deployment' do
      expect(default_provider.start_deployment_timeout!).to eq(time)
    end
  end

  describe "::VALID_GIT_REF" do
    it "matches master" do
      expect("master").to match(valid_git_ref)
    end
    it "matches dev/feature" do
      expect("dev/feature").to match(valid_git_ref)
    end
    it "matches short sha" do
      expect(SecureRandom.hex(4).first(7)).to match(valid_git_ref)
    end
    it "matches full sha" do
      expect(SecureRandom.hex(20)).to match(valid_git_ref)
    end
    it "matches branch with dashes and underscore" do
      expect("my_awesome-branch").to match(valid_git_ref)
    end
    it "matches name with single dot" do
      expect("some.feature").to match(valid_git_ref)
    end

    it "does not allow dot after slash" do
      expect("dev/.branch").not_to match(valid_git_ref)
    end
    it "does not allow space" do
      expect("dev branch").not_to match(valid_git_ref)
    end
    it "does not allow two consecutive dots" do
      expect("dev..branch").not_to match(valid_git_ref)
    end
    it "does not allow trailing /" do
      expect("branch/").not_to match(valid_git_ref)
    end
    it "does not allow trailing ." do
      expect("devbranch.").not_to match(valid_git_ref)
    end
    it "does not allow trailing .lock" do
      expect("devbranch.lock").not_to match(valid_git_ref)
    end
    it "does not allow @{" do
      expect("dev@{branch").not_to match(valid_git_ref)
    end
    it "does not allow \\" do
      expect("dev\\\\branch").not_to match(valid_git_ref)
    end
  end
end

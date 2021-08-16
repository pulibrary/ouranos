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
        'description' => 'a test deployment',
        'payload' => {
          'config' => {
            'deploy_script' => 'deploy.sh'
          },
          'name' => 'test-provider'
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
    end
    let(:custom_payload) do
      {
        'config' => {
          'deploy_script' => 'deploy.sh'
        },
        'name' => 'test-provider'
      }
    end
    let(:custom_payload_json) { JSON.generate(custom_payload) }

    it 'runs the provider' do
      default_provider.run!

      expect(Deployment.all).not_to be_empty
      expect(Deployment.last.custom_payload).to eq(custom_payload_json)
      expect(Deployment.last.environment).to eq(environment)
      expect(Deployment.last.guid).to eq(guid)
      expect(Deployment.last.name).to eq(full_name)
      expect(Deployment.last.name_with_owner).to eq(full_name)
      expect(Deployment.last.output).to eq("https://github.com/pulibrary/ouranos")
      expect(Deployment.last.ref).to eq(ref)
      expect(Deployment.last.sha).to eq("96ea9a5d")
    end

    context 'when an error is encountered due to a server timeout' do
      let(:credentials) { instance_double(Deployment::Credentials) }
      let(:patch_api_gist_request_body) do
        {
          files: {
            stderr: {
              content: "\n\nDEPLOYMENT TIMED OUT AFTER 300 SECONDS"
            }
          },
          public: false
        }
      end
      let(:patch_api_gist_response_body_json) do
        JSON.generate(patch_api_gist_request_body)
      end
      let(:post_api_status_request_body) do
        {
          target_url: nil,
          description: "Deploying from Ouranos v1.0.0",
          state: "failure"
        }
      end
      let(:post_api_status_request_body_json) do
        JSON.generate(post_api_status_request_body)
      end

      before do
        stub_request(:post, "https://api.github.com/repos/pulibrary/ouranos/status")
          .with(
            body: post_api_status_request_body_json,
            headers: {
              'Accept' => 'application/vnd.github.v3+json',
              'Authorization' => 'token <unknown>',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 200)

        stub_request(:patch, "https://api.github.com/gists/gist-id")
          .with(
            body: patch_api_gist_response_body_json,
            headers: {
              'Accept' => 'application/vnd.github.v3+json',
              'Authorization' => 'token <unknown>',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 200)

        allow(credentials).to receive(:setup!).and_raise(POSIX::Spawn::TimeoutExceeded, 'TimeoutExceeded error message')
        allow(Deployment::Credentials).to receive(:new).and_return(credentials)
        allow(Rails.logger).to receive(:info)
      end

      it 'logs the error and updates the output with an error warning' do
        default_provider.run!

        expect(Deployment.all).to be_empty
        expect(Rails.logger).to have_received(:info).with('TimeoutExceeded error message')
      end
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

  describe '#description' do
    it 'accesses description for the provider' do
      expect(default_provider.description).to eq('a test deployment')
    end
  end

  describe '#repository_url' do
    it 'accesses the git repository URL' do
      expect(default_provider.repository_url).to eq('git://localhost.localdomain/invalid')
    end
  end

  describe '#default_branch' do
    it 'accesses the default git repository branch' do
      expect(default_provider.default_branch).to eq('default_branch')
    end
  end

  describe '#clone_url' do
    it 'accesses the URL for the `git clone` invocation' do
      expect(default_provider.clone_url).to eq('git://<unknown>:@localhost.localdomain/invalid')
    end
  end

  describe '#custom_payload_name' do
    it 'accesses the name from the parsed payload invoked with the constructor' do
      expect(default_provider.custom_payload_name).to eq('test-provider')
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

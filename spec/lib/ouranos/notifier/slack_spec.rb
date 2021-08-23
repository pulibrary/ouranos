# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Notifier::Slack do
  include FixtureHelper
  include ComparisonHelper

  subject(:slack_notifier) { described_class.new(data) }

  let(:data_fixture) do
    decoded_fixture_data("deployment-success")
  end
  let(:state) { 'success' }
  let(:deployment_status) do
    {
      "id" => 12_345,
      "state" => state,
      "target_url" => "https://gist.github.com/fa77d9fb1fe41c3bb3a3ffb2c",
      "description" => "Deploying from Heaven v0.5.5"
    }
  end
  let(:data) do
    data_fixture.merge({
                         "deployment_status" => deployment_status
                       })
  end
  let(:sha1) { 'sha' }
  let(:sha2) { 'daf81923' }
  let(:comparison) do
    {
      html_url: "https://github.com/org/repo/compare/#{sha1}...#{sha2}",
      total_commits: 1,
      commits: [
        build_commit_hash("Commit message #123"),
        build_commit_hash("Another commit")
      ],
      files: [{
        additions: 1,
        deletions: 2,
        changes: 3
      }, {
        additions: 1,
        deletions: 2,
        changes: 3
      }]
    }
  end
  let(:comparison_json) do
    JSON.generate(comparison)
  end
  let(:comparison2) do
    {
      html_url: "https://github.com/org/repo/compare/#{sha2}...#{sha2}",
      total_commits: 1,
      commits: [
        build_commit_hash("Commit message #123"),
        build_commit_hash("Another commit")
      ],
      files: [{
        additions: 1,
        deletions: 2,
        changes: 3
      }, {
        additions: 1,
        deletions: 2,
        changes: 3
      }]
    }
  end
  let(:comparison2_json) do
    JSON.generate(comparison2)
  end

  before do
    ENV['SLACK_WEBHOOK_URL'] = "https://example.com"

    stub_request(:get, "https://api.github.com/repos/atmos/my-robot/compare/#{sha1}...#{sha2}").with(
            headers: {
              'Accept' => 'application/vnd.github.v3+json',
              'Authorization' => 'token <unknown>',
              'Content-Type' => 'application/json'
            }
          ).to_return(
            status: 200,
            headers: {
              'Accept' => 'application/vnd.github.v3+json',
              'Content-Type' => 'application/json'
            },
            body: comparison_json
          )
    stub_request(:get, "https://api.github.com/repos/atmos/my-robot/compare/#{sha2}...#{sha2}").with(
            headers: {
              'Accept' => 'application/vnd.github.v3+json',
              'Authorization' => 'token <unknown>',
              'Content-Type' => 'application/json'
            }
          ).to_return(
            status: 200,
            headers: {
              'Accept' => 'application/vnd.github.v3+json',
              'Content-Type' => 'application/json'
            },
            body: comparison2_json
          )
  end

  after do
    ENV['SLACK_WEBHOOK_URL'] = nil
  end

  describe '#post!' do
    let(:payload) do
      {
        channel: "#danger",
        user: "hubot",
        icon_url: "https://octodex.github.com/images/labtocat.png",
        text: "",
        attachments: [
          {
            text: "https://gist.github.com/fa77d9fb1fe41c3bb3a3ffb2c",
            color: "good",
            pretext: " "
          }
        ]
      }
    end
    let(:payload_json) do
      JSON.generate(payload)
    end
    let(:body) do
      {
        "payload" => payload_json
      }
    end
    let(:slack_client) { instance_double(::Slack::Notifier) }

    before do
      stub_request(:post, "https://example.com/").with(
        headers: {
          'Accept' => '*/*',
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      ).to_return(
        status: 200
      )

      allow(slack_client).to receive(:ping)
      allow(::Slack::Notifier).to receive(:new).and_return(slack_client)
    end

    it 'delivers the notification for the default message' do
      slack_notifier.post!
    end

    context 'when the deployment is successful' do
      let(:redis) { instance_double(Redis) }

      before do
        allow(redis).to receive(:set)
        allow(redis).to receive(:get)
        allow(Ouranos).to receive(:redis).and_return(redis)

        slack_notifier.post!
      end

      after do
        allow(Ouranos).to receive(:redis).and_call_original
      end

      it 'enqueues a Redis job for setting the latest revision for the deployed project' do
        expect(redis).to have_received(:set).with("atmos/my-robot-production-revision", "daf81923")
      end

      context 'when notifications for changes are enabled' do
        it 'delivers the notification for the changes in the most recent revision' do
        end
      end
    end
  end

  it "handles pending notifications" do
    Ouranos.redis.set("atmos/my-robot-production-revision", "sha")

    data = decoded_fixture_data("deployment-pending")

    n = described_class.new(data)
    n.comparison = {
      "html_url" => "https://github.com/org/repo/compare/sha...sha"
    }

    result = [
      "[#123456](https://gist.github.com/fa77d9fb1fe41c3bb3a3ffb2c) ",
      ": [atmos](https://github.com/atmos) is deploying ",
      "[my-robot](https://github.com/atmos/my-robot/tree/break-up-notifiers) ",
      "to production ([compare](https://github.com/org/repo/compare/sha...sha))"
    ]

    expect(n.default_message).to eql result.join("")
  end

  it "handles successful deployment statuses" do
    data = decoded_fixture_data("deployment-success")

    n = described_class.new(data)

    result = [
      "[#11627](https://gist.github.com/fa77d9fb1fe41c3bb3a3ffb2c) ",
      ": [atmos](https://github.com/atmos)'s production deployment of ",
      "[my-robot](https://github.com/atmos/my-robot) ",
      "is done! "
    ]
    expect(n.default_message).to eql result.join("")
  end

  it "handles failure deployment statuses" do
    data = decoded_fixture_data("deployment-failure")

    n = described_class.new(data)

    result = [
      "[#123456](https://gist.github.com/fa77d9fb1fe41c3bb3a3ffb2c) ",
      ": [atmos](https://github.com/atmos)'s production deployment of ",
      "[my-robot](https://github.com/atmos/my-robot) ",
      "failed. "
    ]
    expect(n.default_message).to eql result.join("")
  end

  describe '#describe' do
    let(:message) do
      Slack::Notifier::Util::LinkFormatter.format('Test Message')
    end
    let(:payload) do
      {
        channel: '#danger',
        username: 'hubot',
        icon_url: 'https://octodex.github.com/images/labtocat.png',
        text: '',
        attachments: [
          {
            color: 'good',
            pretext: ' ',
            text: 'Test Message'
          }
        ]
      }
    end
    let(:payload_json) do
      payload.to_json
    end
    let(:logger) do
      instance_double(ActiveSupport::Logger)
    end
    let(:slack_account) do
      instance_double(Slack::Notifier)
    end
    let(:comparison) do
      {
        html_url: "https://github.com/org/repo/compare/sha...sha",
        total_commits: 1,
        commits: [
          build_commit_hash("Commit message #123"),
          build_commit_hash("Another commit")
        ],
        files: [{
          additions: 1,
          deletions: 2,
          changes: 3
        }, {
          additions: 1,
          deletions: 2,
          changes: 3
        }]
      }
    end
    let(:comparison_json) do
      JSON.generate(comparison)
    end

    before do
      allow(slack_account).to receive(:ping)
      allow(Slack::Notifier).to receive(:new).and_return(slack_account)

      stub_request(:post, "https://example.com/").with(
        body: {
          "payload" => payload_json
        }
      ).to_return(
        status: 200,
        headers: {
          'Accept' => 'application/vnd.github.v3+json',
          'Content-Type' => 'application/json'
        },
        body: comparison_json
      )

      allow(logger).to receive(:info)
      allow(Rails).to receive(:logger).and_return(logger)

      slack_notifier.deliver(message)
    end

    it 'transmits a message using the Slack API' do
      expect(logger).to have_received(:info).with('slack: Test Message')
      expect(logger).to have_received(:info).with('message: Test Message')

      expect(slack_account).to have_received(:ping).with(
        '',
        channel: '#danger',
        username: 'hubot',
        icon_url: 'https://octodex.github.com/images/labtocat.png',
        attachments: [
          {
            color: 'good',
            pretext: ' ',
            text: 'Test Message'
          }
        ]
      )
    end
  end

  describe '#default_message' do
    context 'when the deployment encounters an error' do
      let(:state) { 'error' }
      it 'indicates in the message that an error has occurred' do
        expect(slack_notifier.default_message).to include("[my-robot](https://github.com/atmos/my-robot) has errors. ¯_(ツ)_/¯")
      end
    end

    context 'when the deployment an supported state' do
      let(:state) { 'invalid' }
      let(:logger) { instance_double(ActiveSupport::Logger) }
      before do
        allow(logger).to receive(:error)
        allow(Rails).to receive(:logger).and_return(logger)
        slack_notifier.default_message
      end
      it 'logs an error for unsupported deployment states' do
        expect(logger).to have_received(:error).with("Unhandled deployment state, invalid")
      end
    end
  end

  describe '#linked' do
    it 'constructs a comparison between the new deployment and the last revision' do
      expect(slack_notifier.linked).to be_a(Ouranos::Comparison::Linked)

      expect(slack_notifier.linked.comparison).to include("commits" => [
                                                            { "author" => {
                                                              "html_url" => "https://github.com/login", "login" => "login"
                                                            },
                                                              "commit" => { "message" => "Commit message #123" },
                                                              "html_url" => "https://github.com/org/repo/commit/sha",
                                                              "sha" => "sha" }, {
                                                                "author" => {
                                                                  "html_url" => "https://github.com/login", "login" => "login"
                                                                }, "commit" => {
                                                                  "message" => "Another commit"
                                                                }, "html_url" => "https://github.com/org/repo/commit/sha", "sha" => "sha"
                                                              }
                                                          ])
      expect(slack_notifier.linked.comparison).to include("files" => [
                                                            { "additions" => 1, "changes" => 3, "deletions" => 2 },
                                                            { "additions" => 1, "changes" => 3, "deletions" => 2 }
                                                          ])
      expect(slack_notifier.linked.comparison).to include("html_url")
      expect(slack_notifier.linked.comparison["html_url"]).to include("https://github.com/org/repo/compare/")
      expect(slack_notifier.linked.comparison).to include(
        "total_commits" => 1
      )
    end
  end

  describe '#changes' do
    it 'identifies the changes between the deployed revision the last deployed revision' do
      expect(slack_notifier.changes).to be_a(String)

      expect(slack_notifier.changes).to include('[sha](https://github.com/org/repo/commit/sha) by [login](https://github.com/login): Commit message [#123](https://github.com/atmos/my-robot/issues/123)')
      expect(slack_notifier.changes).to include('[sha](https://github.com/org/repo/commit/sha) by [login](https://github.com/login): Another commit')
    end
  end
end

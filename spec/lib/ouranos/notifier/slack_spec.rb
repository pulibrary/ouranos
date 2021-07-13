# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Notifier::Slack do
  include FixtureHelper

  let(:data) do
    decoded_fixture_data("deployment-success")
  end

  let(:slack_notifier) do
    described_class.new(data)
  end

  before do
    ENV['SLACK_WEBHOOK_URL'] = "https://example.com"
  end

  after do
    ENV['SLACK_WEBHOOK_URL'] = nil
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

    before do
      allow(slack_account).to receive(:ping)
      allow(Slack::Notifier).to receive(:new).and_return(slack_account)

      stub_request(:post, "https://example.com/").with(
        body: {
          "payload" => payload_json
        }
      ).to_return(status: 200)

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
end

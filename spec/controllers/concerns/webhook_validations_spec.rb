# frozen_string_literal: true
require "rails_helper"

describe WebhookValidations do
  let(:remote_ip) do
    ip = Socket.ip_address_list.detect(&:ipv4_private?)
    ip.ip_address
  end
  let(:octokit_client_meta_hooks) do
    [
      remote_ip
    ]
  end
  let(:github_meta_url) { "https://api.github.com/meta" }
  before do
    stub_request(:get, github_meta_url)
      .to_return(
        status: 200,
        headers: {
          "Content-Type" => "application/vnd.github.v3+json"
        },
        body: {
          hooks: octokit_client_meta_hooks
        }.to_json
      )
  end

  class WebhookValidationsTester
    class Request
      def initialize(ip)
        @ip = ip
      end
      attr_accessor :ip
    end
    include WebhookValidations

    def initialize(ip)
      @ip = ip
    end

    def request
      # rubocop:disable RSpec/InstanceVariable
      Request.new(@ip)
      # rubocop:enable RSpec/InstanceVariable
    end
  end

  it "makes methods available" do
    tester1 = WebhookValidationsTester.new(remote_ip)
    expect(tester1).to be_valid_incoming_webhook_address

    tester2 = WebhookValidationsTester.new("127.1.1.255")
    expect(tester2).not_to be_valid_incoming_webhook_address
  end

  describe '#valid_incoming_webhook_address?' do
    context 'when the GitHub API client uses a custom URL' do
      before do
        allow(Octokit).to receive(:api_endpoint).and_return('https://gitlab.local')
      end

      it 'determines the webhook address to be valid' do
        tester1 = WebhookValidationsTester.new(remote_ip)
        expect(tester1).to be_valid_incoming_webhook_address

        tester2 = WebhookValidationsTester.new("127.1.1.255")
        expect(tester2).to be_valid_incoming_webhook_address
      end
    end
  end
end

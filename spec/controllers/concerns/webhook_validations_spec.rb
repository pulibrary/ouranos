# frozen_string_literal: true
require "rails_helper"

describe WebhookValidations do
  include MetaHelper

  before { stub_meta }

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
    klass = WebhookValidationsTester.new("192.30.252.41")
    expect(klass).to be_valid_incoming_webhook_address
    klass = WebhookValidationsTester.new("127.0.0.1")
    expect(klass).not_to be_valid_incoming_webhook_address
  end
end

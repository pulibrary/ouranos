# frozen_string_literal: true
require "rails_helper"

describe Ouranos::Notifier do
  let(:child_class) do
    Class.new { include Ouranos::Notifier }
  end

  before do
    stub_const('Ouranos::Notifier::CustomNotifier', child_class)
  end

  describe '.slack?' do
    it 'determines whether or not Slack has been configured' do
      ENV['SLACK_WEBHOOK_URL'] = 'true'

      expect(described_class.slack?).to be true
      ENV['SLACK_WEBHOOK_URL'] = nil
      expect(described_class.slack?).to be false
    end
  end

  describe '.for' do
    subject(:notified) { described_class.for(payload) }
    let(:payload) do
      {}
    end

    it 'delegates to the default notification handler' do
      expect(notified).to be_a(Ouranos::Notifier::Default)
    end

    context 'when the Slack configuration has been detected' do
      before do
        ENV['SLACK_WEBHOOK_URL'] = 'true'
      end

      after do
        ENV['SLACK_WEBHOOK_URL'] = nil
      end

      it 'constructs a Slack notifier' do
        expect(notified).to be_a(Ouranos::Notifier::Slack)
      end
    end
  end
end

# frozen_string_literal: true

module Ouranos
  # The Notifier module
  module Notifier
    autoload(:Default, Rails.root.join('lib', 'ouranos', 'notifier', 'default'))
    autoload(:Slack, Rails.root.join('lib', 'ouranos', 'notifier', 'slack'))

    def self.for(payload)
      if slack?
        ::Ouranos::Notifier::Slack.new(payload)
      elsif Rails.env.test?
        # noop on posting
      end
    end

    def self.slack?
      !ENV['SLACK_WEBHOOK_URL'].nil?
    end
  end
end

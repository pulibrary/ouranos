# frozen_string_literal: true

module Ouranos
  # The Notifier module
  module Notifier
    autoload(:Default, Rails.root.join('lib', 'ouranos', 'notifier', 'default'))
    autoload(:Slack, Rails.root.join('lib', 'ouranos', 'notifier', 'slack'))

    def self.for(payload)
      return Slack.new(payload) if slack?

      Default.new(payload)
    end

    def self.slack?
      !ENV['SLACK_WEBHOOK_URL'].nil?
    end
  end
end

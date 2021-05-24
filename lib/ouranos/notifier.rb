# frozen_string_literal: true

require 'ouranos/notifier/default'
require 'ouranos/notifier/slack'

module Ouranos
  # The Notifier module
  module Notifier
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

# frozen_string_literal: true
# module Deployment::Status::Matchers
module DeploymentStatusMatchers
  extend RSpec::Matchers::DSL

  def event_match?(event, options)
    options.deep_stringify_keys!.all? do |key, value|
      event.fetch(key) == value
    end
  end

  matcher :have_event do |options|
    match do |deployment_status|
      deployment_status.deliveries.any? do |event|
        event_match?(event, options)
      end
    end
  end
end

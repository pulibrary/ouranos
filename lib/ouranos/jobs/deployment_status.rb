# frozen_string_literal: true

module Ouranos
  module Jobs
    # A deployment status handler
    class DeploymentStatus
      @queue = :deployment_statuses

      def self.perform(payload)
        notifier = Ouranos::Notifier.for(payload)
        notifier&.post!
      end
    end
  end
end

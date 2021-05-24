# frozen_string_literal: true

module Ouranos
  # A job to handle commit statuses
  module Jobs
    autoload(:Deployment, Rails.root.join('lib', 'ouranos', 'jobs', 'deployment'))
    autoload(:DeploymentStatus, Rails.root.join('lib', 'ouranos', 'jobs', 'deployment_status'))
    autoload(:Status, Rails.root.join('lib', 'ouranos', 'jobs', 'status'))
    autoload(:LockedError, Rails.root.join('lib', 'ouranos', 'jobs', 'locked_error'))
    autoload(:EnvironmentLock, Rails.root.join('lib', 'ouranos', 'jobs', 'environment_lock'))
    autoload(:EnvironmentUnlock, Rails.root.join('lib', 'ouranos', 'jobs', 'environment_unlock'))
    autoload(:EnvironmentLockedError, Rails.root.join('lib', 'ouranos', 'jobs', 'environment_locked_error'))
  end
end

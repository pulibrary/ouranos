# frozen_string_literal: true
# A class to handle incoming webhooks
class Receiver
  @queue = :events

  attr_accessor :event, :guid, :data

  def initialize(event, guid, data)
    @guid  = guid
    @event = event
    @data  = data
  end

  def self.perform(event, guid, data)
    receiver = new(event, guid, data)

    if receiver.active_repository?
      receiver.run!
    else
      Rails.logger.info "Repository is not configured to deploy: #{receiver.full_name}"
    end
  end

  def full_name
    data["repository"] && data["repository"]["full_name"]
  end

  def active_repository?
    if data["repository"]
      name  = data["repository"]["name"]
      owner = data["repository"]["owner"]["login"]
      repository = Repository.find_or_create_by(name: name, owner: owner)
      repository.active?
    else
      false
    end
  end

  def run_deployment!
    return if LockReceiver.new(data).run!

    if Ouranos::Jobs::Deployment.locked?(guid, data)
      Rails.logger.info "Deployment locked for: #{Ouranos::Jobs::Deployment.identifier(guid, data)}"
      Resque.enqueue(Ouranos::Jobs::LockedError, guid, data)
    else
      Resque.enqueue(Ouranos::Jobs::Deployment, guid, data)
    end
  end

  def run!
    if event == "deployment"
      run_deployment!
    elsif event == "deployment_status"
      Resque.enqueue(Ouranos::Jobs::DeploymentStatus, data)
    elsif event == "status"
      Resque.enqueue(Ouranos::Jobs::Status, guid, data)
    else
      Rails.logger.info "Unhandled event type, #{event}."
    end
  end
end

# frozen_string_literal: true

class EventsController < ApplicationController
  include WebhookValidations

  before_action :verify_incoming_webhook_address!
  skip_before_action :verify_authenticity_token, only: [:create]

  GITHUB_EVENT_HEADER = "HTTP_X_GITHUB_EVENT"
  GITHUB_DELIVERY_HEADER = "HTTP_X_GITHUB_DELIVERY"

  def create
    if valid_events.include?(event)
      request.body.rewind

      Resque.enqueue(Receiver, event, delivery, event_params)

      render json: {}, status: :created
    else
      render json: {}, status: :unprocessable_entity
    end
  end

  def valid_events
    %w[deployment deployment_status status ping]
  end

  private

  def request_form_params
    request.headers[Rack::RACK_REQUEST_FORM_HASH]
  end

  def request_form_headers
    request_form_params["headers"]
  end

  def event
    request_form_headers[GITHUB_EVENT_HEADER]
  end

  def delivery
    request_form_headers[GITHUB_DELIVERY_HEADER]
  end

  def event_params
    params.permit!
  end
end

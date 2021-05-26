# frozen_string_literal: true
require "rails_helper"

describe "Receiving GitHub hooks", type: :request do
  include FixtureHelper

  let(:remote_ip) { "127.0.0.1" }
  let(:github_meta_url) { "https://api.github.com/meta" }
  let(:octokit_client_meta_hooks) do
    [
      '127.0.0.1'
    ]
  end

  before do
    stub_request(:get, github_meta_url)
      .to_return(
        status: 200,
        headers: {
          "Content-Type" => "application/vnd.github.v3+json"
        },
        body: {
          hooks: octokit_client_meta_hooks
        }.to_json
      )
  end

  context 'when transmitting from an invalid host IP' do
    let(:remote_ip) { "127.1.1.255" }

    describe "POST /events" do
      let(:headers) do
        {
          "REMOTE_ADDR" => remote_ip,
          "X_FORWARDED_FOR" => remote_ip,
          "HTTP_X_GITHUB_EVENT" => 'ping',
          "HTTP_X_GITHUB_DELIVERY" => SecureRandom.uuid
        }
      end

      it "returns a forbidden error to invalid hosts" do
        post("/events", headers: headers, params: fixture_data("ping"))

        expect(response.status).to eq(403)
      end
    end
  end

  context 'when transmitting from a valid host IP' do
    before do
      stub_request(:get, github_meta_url)
        .to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/vnd.github.v3+json"
          },
          body: {
            hooks: octokit_client_meta_hooks
          }.to_json
        )
    end

    describe "POST /events" do
      context 'when transmitting a JSON request' do
        let(:headers) do
          {
            "Accept" => "application/json",
            "Content-Type" => "application/json",
            "HTTP_X_GITHUB_EVENT" => 'invalid',
            "HTTP_X_GITHUB_DELIVERY" => SecureRandom.uuid
          }
        end

        it "returns a unprocessable error for invalid events" do
          post("/events", headers: headers, params: {})

          expect(response.status).to be(422)
        end
      end

      let(:headers) do
        {
          "REMOTE_ADDR" => remote_ip,
          "X_FORWARDED_FOR" => remote_ip,
          "HTTP_X_GITHUB_EVENT" => 'ping',
          "HTTP_X_GITHUB_DELIVERY" => SecureRandom.uuid
        }
      end

      it "handles ping events from valid hosts" do
        post("/events", headers: headers, params: fixture_data("ping"))

        expect(response).to be_successful
        expect(response.status).to be(201)
      end

      context 'when transmitting a JSON request' do
        let(:headers) do
          {
            "Accept" => "application/json",
            "Content-Type" => "application/json",
            "REMOTE_ADDR" => remote_ip,
            "X_FORWARDED_FOR" => remote_ip,
            "HTTP_X_GITHUB_EVENT" => 'deployment',
            "HTTP_X_GITHUB_DELIVERY" => SecureRandom.uuid
          }
        end

        let(:params) { fixture_data("deployment") }

        it "handles deployment events from valid hosts" do
          post("/events", headers: headers, params: params)

          expect(response).to be_successful
          expect(response.status).to be(201)
        end
      end

      let(:headers) do
        {
          "REMOTE_ADDR" => remote_ip,
          "X_FORWARDED_FOR" => remote_ip,
          "HTTP_X_GITHUB_EVENT" => 'deployment_status',
          "HTTP_X_GITHUB_DELIVERY" => SecureRandom.uuid
        }
      end

      it "handles deployment status events from valid hosts" do
        post "/events", headers: headers, params: fixture_data("deployment-success")

        expect(response).to be_successful
        expect(response.status).to be(201)
      end
    end
  end
end

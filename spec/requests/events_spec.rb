# frozen_string_literal: true
require "rails_helper"

describe "Receiving GitHub hooks", type: :request do
  let(:remote_ip) do
    ip = Socket.ip_address_list.detect(&:ipv4_private?)
    ip.ip_address
  end
  let(:octokit_client_meta_hooks) do
    [
      remote_ip
    ]
  end
  let(:github_meta_url) { "https://api.github.com/meta" }
  let(:fixture_file_name) do
    'ping'
  end
  let(:fixture_file_path) do
    Rails.root.join("spec", "fixtures", "#{fixture_file_name}.json")
  end
  let(:params) do
    File.read(fixture_file_path)
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
    describe "POST /events" do
      let(:headers) do
        {
          "REMOTE_ADDR" => '127.1.1.1',
          "X_FORWARDED_FOR" => '127.1.1.1',
          "HTTP_X_GITHUB_EVENT" => 'ping',
          "HTTP_X_GITHUB_DELIVERY" => SecureRandom.uuid
        }
      end

      it "returns a forbidden error to invalid hosts" do
        post("/events", headers: headers, params: params)

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
            "REMOTE_ADDR" => remote_ip,
            "X_FORWARDED_FOR" => remote_ip,
            "HTTP_X_GITHUB_EVENT" => 'invalid',
            "HTTP_X_GITHUB_DELIVERY" => SecureRandom.uuid
          }
        end

        it "returns a unprocessable error for invalid events" do
          post("/events", headers: headers, params: {})

          expect(response.status).to eq(422)
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
        post("/events", headers: headers, params: params)

        expect(response.status).to eq(201)
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

        let(:fixture_file_name) do
          'deployment'
        end

        it "handles deployment events from valid hosts" do
          post("/events", headers: headers, params: params)

          expect(response.status).to eq(201)
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

      context 'when transmitting a POST request encoding the successful state of a deployment' do
        let(:fixture_file_name) do
          'deployment-success'
        end

        it "handles deployment status events from valid hosts" do
          post "/events", headers: headers, params: params

          expect(response.status).to eq(201)
        end
      end
    end
  end
end

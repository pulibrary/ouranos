# frozen_string_literal: true
require "rails_helper"

describe "Visiting in a browser", type: :request do
  let(:github_meta_url) { "https://api.github.com/meta" }
  let(:headers) do
    {
      "Accept" => "application/json",
      "Content-Type" => "application/json"
    }
  end

  before do
    stub_request(:get, github_meta_url)
      .to_return(
        status: 200,
        headers: {
          "Content-Type" => "application/vnd.github.v3+json"
        },
        body: {
          hooks: [
            "192.30.252.0/22"
          ]
        }.to_json
      )
  end

  describe "GET /" do
    it "redirects to the GitHub repository" do
      get("/", headers: headers)

      expect(response).to be_redirect
      expect(response.headers["Location"]).to eq(
        "https://github.com/pulibrary/ouranos"
      )
    end
  end
end

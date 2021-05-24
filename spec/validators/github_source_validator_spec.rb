# frozen_string_literal: true
require "rails_helper"

describe GithubSourceValidator do
  let(:github_meta_url) { "https://api.github.com/meta" }

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

  context "verifies IPs" do
    xit "returns production" do
      expect(described_class.new("127.0.0.1")).not_to be_valid
      expect(described_class.new("192.30.252.41")).to be_valid
      expect(described_class.new("192.30.252.46")).to be_valid
    end
  end
end

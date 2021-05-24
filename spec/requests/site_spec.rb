# frozen_string_literal: true
require "rails_helper"

describe "Visiting in a browser", type: :request do
  before do
    send_and_accept_json
    stub_meta
  end

  describe "GET /" do
    it "redirects to the GitHub repository" do
      get "/"

      expect(last_response).to be_redirect
      expect(last_response.headers["Location"]).to eq(
        "https://github.com/pulibrary/ouranos"
      )
    end
  end
end

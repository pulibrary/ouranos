# frozen_string_literal: true
module MetaHelper
  def github_meta_url
    "https://api.github.com/meta"
  end

  def stub_meta
    request_params = {
      "headers" => {
        "Accept" => "application/vnd.github.v3+json",
        "User-Agent" => "Octokit Ruby Gem #{Octokit::VERSION}"
      }
    }

    stub_request(:get, github_meta_url)
      .with(request_params)
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
end

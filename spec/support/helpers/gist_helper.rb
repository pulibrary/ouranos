# frozen_string_literal: true
module GistHelper
  def stub_gists
    stub_request(:post, "https://api.github.com/gists")
      .to_return(
        headers: {
          'Content-Type': 'application/vnd.github.v3+json'
        },
        status: 200,
        #:body => double(
        #  "id" => "cd520d99c3087f2d18b4",
        #  :html_url => "https://gist.github.com/atmos/cd520d99c3087f2d18b4"
        # )
        body: {
          "id" => "cd520d99c3087f2d18b4",
          :html_url => "https://gist.github.com/atmos/cd520d99c3087f2d18b4"
        }.to_json
      )

    stub_request(:patch, "https://api.github.com/gists/cd520d99c3087f2d18b4")
      .to_return(
        headers: {
          'Content-Type': 'application/vnd.github.v3+json'
        },
        status: 200,
        body: ""
      )
  end
end

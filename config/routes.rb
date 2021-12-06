# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get "/" => redirect(ENV["ROOT_REDIRECT_URL"] || "https://github.com/pulibrary/ouranos")

  auth_opts =
    if ENV["GITHUB_TEAM_ID"]
      { team: :employees }
    elsif ENV["GITHUB_ORG"]
      { org: ENV["GITHUB_ORG"] }
    else
      { }
    end

  github_authenticate(auth_opts) do
    mount Resque::Server.new, at: "/resque"
  end

  post "/events" => "events#create"
end

# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get "/" => redirect(ENV["ROOT_REDIRECT_URL"] || "https://github.com/pulibrary/ouranos")

  github_authenticate(team: :employees) do
    mount Resque::Server.new, at: "/resque"
  end

  post "/events" => "events#create"
end

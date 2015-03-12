Rails.application.routes.draw do
  namespace :api do
    get 'hour' => "main#hour"
    get 'listens' => "listens#index"
    get 'listens/compare' => "listens#compare"
    get 'listens/hour' => "listens#hour"
    get 'sessions' => "main#sessions"
  end

  get "/compare" => "home#compare"
  get "/hourly" => "home#hourly"
  root to:"home#dashboard"
end

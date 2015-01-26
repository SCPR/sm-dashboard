Rails.application.routes.draw do
  namespace :api do
    get 'listens' => "listens#index"
  end

  root to:"home#dashboard"
end

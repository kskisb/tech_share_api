Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "/auth/signup", to: "users#create"
      post "/auth/login", to: "sessions#create"
      get "/auth/me", to: "users#me"

      resources :posts, only: [ :create ]
    end
  end
end

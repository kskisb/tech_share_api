Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "/auth/signup", to: "users#create"
      post "/auth/login", to: "sessions#create"
      get "/auth/me", to: "users#me"

      resources :posts do
        resources :comments, only: [ :create, :destroy ]
        resource :like, only: [ :create, :destroy ]
      end

      resources :tags, only: [ :index ]
    end
  end
end

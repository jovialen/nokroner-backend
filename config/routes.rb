Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "pages#home", as: :home

  # User identification and authentication
  get "login" => "pages#login", as: :login
  get "register" => "pages#register", as: :register

  resources :passwords, param: :token

  # API
  namespace :api do
    namespace :v1 do
      # User authentication, registration and deletion
      post "login" => "sessions#create"
      delete "logout" => "sessions#destroy"
      post "register" => "user#create"
      get "me" => "user#show"
      delete "me" => "user#destroy"

      # Profile information
      get "me/profile" => "profile#show"
      patch "me/profile" => "profile#update"

      # Owners
      resources :owners
    end
  end
end

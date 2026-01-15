Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # User identification and authentication
  resources :passwords, param: :token

  # API
  namespace :api do
    namespace :v1 do
      # User authentication and management
      post "login" => "sessions#create"
      delete "logout" => "sessions#destroy"
      post "register" => "user#create"
      get "me" => "user#show"
      delete "me" => "user#destroy"
    end
  end
end

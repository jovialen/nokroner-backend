Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  resource :session
  resources :passwords, param: :token

  resource :registration, only: [:new, :create, :destroy]

  get "users/me" => "users#show"

  # Application
  resources :owners
  resources :accounts
end

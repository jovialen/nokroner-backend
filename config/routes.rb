Rails.application.routes.draw do
  # Health check
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Authentication
  resources :sessions
  resources :passwords, param: :token

  resource :registration, only: [ :new, :create, :destroy ]

  get 'user' => 'users#show'

  # Application
  resources :owners
  resources :accounts
  resources :transactions
end

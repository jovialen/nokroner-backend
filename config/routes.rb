Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  post "register" => "user#create"
  get "user"      => "user#show"
  patch "user"    => "user#update"
  put "user"   => "user#update"
  delete "user"   => "user#destroy"

  post "auth/login"    => "sessions#create"
  post "auth/refresh"  => "sessions#update"
  delete "auth/logout" => "sessions#destroy"

  # Application
  resources :groups
  resources :accounts
end

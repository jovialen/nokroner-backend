Rails.application.routes.draw do
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
  resources :accounts do
    member do
      get "history" => "accounts#show_history"
    end
  end
  resources :transactions
  resources :subscriptions do
    member do
      get "transactions" => "subscriptions#show_transactions"
    end
  end
end

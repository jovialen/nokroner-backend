Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Add automatically generated API documentation on /docs, curtesy of the
  # OasRails gem
  mount OasRails::Engine => "/docs", as: :docs

  # Home page
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
      resources :owners do
        # Accounts belong exclusively to a single owner, so it makes sense to
        # be able to easily get the accounts for a specific owner.
        resources :accounts
      end

      # However, it should also be possible to query all accounts regardless of
      # the owner
      resources :accounts do
        # It should also be possible to get transactions relevant to an account
        # through its route
        member do
          get "transactions" => "accounts#transactions", as: :transactions
          get "transactions/sent" => "accounts#sent", as: :sent_transactions
          get "transactions/received" => "accounts#received", as: :received_transactions
        end
      end

      # While also having a common route for all transactions
      resources :transactions
    end
  end
end

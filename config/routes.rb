Rails.application.routes.draw do
  get "up" => "rails/health#show", :as => :rails_health_check

  scope '/api' do
    match '*path', to: redirect('/api/v1/%{path}'), via: :all, constraints: ->(req) { !req.path.start_with?('/api/v1') }
  end

  namespace :api do
    namespace :v1 do
      resources :accounts
      resources :transactions
    end
  end
end

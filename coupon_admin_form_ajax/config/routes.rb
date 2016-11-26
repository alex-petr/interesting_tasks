Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :admin do
        resources :brands, only: [:index, :create], defaults: { format: :json }
        resources :donors, only: [:index, :create], defaults: { format: :json }
        resources :sellers, only: [:index, :create], defaults: { format: :json }
      end
    end
  end
end

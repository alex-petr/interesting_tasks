Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :coupons, except: [:new, :edit], defaults: { format: :json }
      resources :coupon_types, only: [:index], defaults: { format: :json }
    end
  end
end

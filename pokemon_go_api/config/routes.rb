Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      get 'pokemon_go_users/leader_board'
      get 'pokemon_go_users/leader_board_weekly'
      resources :pokemon_go_users, except: [:new, :edit], defaults: { format: :json } do
        resources :pokemon_go_locations, except: [:new, :edit], defaults: { format: :json }
      end
      resources :pokemon_go_locations, except: [:new, :edit], defaults: { format: :json } do
        put 'up_vote'
        put 'down_vote'
      end
    end
  end
end

Rails.application.routes.draw do
  root "games#index"
  get "/chess" => "games#show", as: :chess_game
  post "/chess/:id/move" => "games#move", as: :chess_move
  post "/chess/:id/computer_move" => "games#computer_move", as: :chess_computer_move
  get "/chess/:id/hint" => "games#hint", as: :chess_hint
  post "/chess/new" => "games#create", as: :new_chess_game
  get "/chess/:id" => "games#show", as: :saved_chess_game
  post "/chess/:id/reset" => "games#reset", as: :reset_chess_game
  get "/chess/:id/legal_moves/:from" => "games#legal_moves", as: :chess_legal_moves
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end

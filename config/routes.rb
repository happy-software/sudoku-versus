Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: 'home#index'
  get '/new', to: 'home#new'
  post '/create_challenge', to: 'home#create_challenge'
  post '/accept_challenge', to: 'home#accept_challenge'
  get '/join_match/:match_key', to: 'home#join_match', as: 'join_match'
  resources :books, only: [:index]

  post '/check_input', to: 'game#check_input'

  resources :games, only: [:show] do
    post :check_input, as: "check_input"

    post :create_rematch, to: 'games#create_rematch', as: 'create_rematch'
    post :accept_rematch, to: 'games#accept_rematch', as: 'accept_rematch'
    post :reject_rematch, to: 'games#reject_rematch', as: 'reject_rematch'
  end
end

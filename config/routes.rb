Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: 'home#index'
  get '/new', to: 'home#new'
  post '/create_challenge', to: 'home#create_challenge'
  post '/accept_challenge', to: 'home#accept_challenge'
  get '/join_match/:match_key', to: 'home#join_match', as: 'join_match'

  post '/check_input', to: 'game#check_input'
end

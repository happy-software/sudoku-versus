Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: 'home#index'
  get '/new', to: 'home#new'
  post '/create_challenge', to: 'home#create_challenge'
  get '/waiting_for_challenger/:match_uuid', to: 'home#waiting_for_challenger', as: 'waiting_for_challenger'
end

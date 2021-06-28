Rails.application.routes.draw do
  root :to => 'home#index'
  get "examples", :to=>"home#examples", :as=>"examples"
  post "solve", :to=>"home#solve", :as=>"solve"
  post "show", :to=>"home#show", :as=>"show"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end

Rails.application.routes.draw do
  root "home_pages#index"
  resource :session
  resources :passwords, param: :token

  resources :instagrams, only: [:new]
  get "post", controller: "home_pages", as: "post"

  post "instagrams", to: "instagrams#create", as: "instagrams"
  post "instagrams/upload_base64_image", to: "instagrams#upload_base64_image"

  get '/auth/facebook/callback', to: 'instagrams#facebook_callback'
  get '/auth/failure', to: redirect('/')
end

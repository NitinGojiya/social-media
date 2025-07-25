Rails.application.routes.draw do
  root "home_pages#index"
  resource :session
  resources :passwords, param: :token

  resources :posts, only: [:new]
  get "post", controller: "home_pages", as: "post"
  get "link_account", controller: "home_pages", as: "link_account"

  post "instagrams", to: "posts#create", as: "instagrams"
  post "instagrams/upload_base64_image", to: "posts#upload_base64_image"

  get '/auth/facebook/callback', to: 'posts#facebook_callback',as:"facebook_callback"
  get '/auth/failure', to: redirect('/')
end

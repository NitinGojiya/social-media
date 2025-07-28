Rails.application.routes.draw do
  root "home_pages#index"
  resource :session
  resources :passwords, param: :token

  resources :posts, only: [:new]
  get "post", to: "home_pages#post", as: "post"
  get "link_account", controller: "home_pages", as: "link_account"

  # ig and fb routes
  post "instagrams", to: "posts#create", as: "instagrams"

  get '/auth/facebook/callback', to: 'posts#facebook_callback',as:"facebook_callback"
  get '/auth/failure', to: redirect('/')

  # linkdin routes
  # post "linkdin", to: "linkdin_posts#create", as: "linkdin"
  # get '/auth/linkedin/callback', to: 'linkedin_posts#linkedin_session'
  # get '/auth/failure', to: redirect('/')

  get '/auth/linkedin', to: 'linkedin_posts#auth'
  get '/auth/linkedin/callback', to: 'linkedin_posts#callback'
  get '/linkedin/profile', to: 'linkedin_posts#profile', as: 'linkedin_profile'



end

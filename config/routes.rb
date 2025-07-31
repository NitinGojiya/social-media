Rails.application.routes.draw do
  root "home_pages#index"
  resource :session
  resources :passwords, param: :token

  resources :posts, only: [:new]
  delete "/delete_post/:id", to: "posts#destroy", as: :delete_post
  get "post", to: "home_pages#post", as: "post"
  get "link_account", controller: "home_pages", as: "link_account"
  get 'calendar_events', to: 'home_pages#calendar_events'
  get 'calendar', controller: 'home_pages'

  # ig and fb routes
  post "instagrams", to: "posts#create", as: "instagrams"

  get '/auth/facebook/callback', to: 'posts#facebook_callback',as:"facebook_callback"
  get '/auth/failure', to: redirect('/')

  get '/auth/linkedin', to: 'linkedin_posts#auth'
  get '/auth/linkedin/callback', to: 'linkedin_posts#callback'
  get '/linkedin/profile', to: 'linkedin_posts#profile', as: 'linkedin_profile'
  get "/linkedin/post", to: "linkedin_posts#post_to_linkedin", as: :linkedin_post

  post "/linkedin/post_with_image", to: "posts#post_with_image", as: :linkedin_post_with_image

end

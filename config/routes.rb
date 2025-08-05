Rails.application.routes.draw do
  root "home_pages#index"
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'
  resource :session
  resources :passwords, param: :token

  resources :posts, only: [:new]
  patch "scheduled_update/:id", to: "posts#scheduled_update", as: "scheduled_update"
  delete "/delete_post/:id", to: "posts#destroy", as: :delete_post
  delete "/scheduled_posts_delete/:id", to: "posts#scheduled_posts_delete", as: :scheduled_posts_delete

  get "post", to: "home_pages#post", as: "post"
  get "link_account", controller: "home_pages", as: "link_account"
  get 'calendar_events', to: 'home_pages#calendar_events'
  get 'calendar', controller: 'home_pages'

  # ig and fb routes
  post "ig_fb_posts", to: "posts#create", as: "ig_fb_posts"

  get '/auth/facebook/callback', to: 'facebook_links#facebook_callback',as:"facebook_callback"
  get '/auth/failure', to: redirect('/')

  get '/auth/linkedin', to: 'linkedin_links#auth'
  get '/auth/linkedin/callback', to: 'linkedin_links#callback'


  post "/linkedin/create_linkedin_post", to: "posts#create_linkedin_post", as: :create_linkedin_post
  delete "/delete_linkedin_post/:id", to: "posts#delete_linkedin_post", as: :delete_linkedin_post


  # ai
  post "/ai/generate_caption", to: "geminiai#generate_caption", as: :generate_caption

end

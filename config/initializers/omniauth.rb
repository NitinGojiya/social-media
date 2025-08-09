
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook,
           ENV['FACEBOOK_CLIENT_ID'],
           ENV['FACEBOOK_CLIENT_SECRET'],
           scope: 'email,public_profile,pages_show_list,pages_read_engagement,pages_manage_posts,pages_manage_metadata,instagram_basic,instagram_content_publish',
           info_fields: 'email,name'
  provider :twitter,
    ENV['TWITTER_API_KEY'],
    ENV['TWITTER_API_SECRET'],
    authorize_params: {
      force_login: 'true', # Optional: force fresh login
      include_email: 'true'
    }
      provider :google_oauth2,
           ENV['GOOGLE_CLIENT_ID'],
           ENV['GOOGLE_CLIENT_SECRET'],
           { scope: 'email,profile', prompt: 'select_account' }
end

OmniAuth.config.allowed_request_methods = [:get, :post]


Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook,
           ENV['FACEBOOK_CLIENT_ID'],
           ENV['FACEBOOK_CLIENT_SECRET'],
           scope: 'email,public_profile,pages_show_list,pages_read_engagement,pages_manage_posts,pages_manage_metadata,instagram_basic,instagram_content_publish',
           info_fields: 'email,name'
  # provider :linkedin,
  #          ENV['LINKEDIN_CLIENT_ID'],
  #          ENV['LINKEDIN_CLIENT_SECRET'],
  #          scope: 'r_liteprofile r_emailaddress w_member_social',
  #          redirect_uri: 'https://5e75be2c9477.ngrok-free.app/auth/linkedin/callback'

end

OmniAuth.config.allowed_request_methods = [:get, :post]



Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook,
           "1123795822946011",
           "56df8e67165e43b4f180cfda70fbb67f",
           scope: 'email,public_profile,pages_show_list,pages_read_engagement,pages_manage_posts,pages_manage_metadata,instagram_basic,instagram_content_publish',
           info_fields: 'email,name'
end

OmniAuth.config.allowed_request_methods = [:get, :post]

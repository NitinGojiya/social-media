class FacebookLinksController < ApplicationController
  def facebook_callback
    auth = request.env["omniauth.auth"]
    token = auth["credentials"]["token"]

    # Step 1: Get Facebook Pages
    pages_uri = URI("https://graph.facebook.com/v18.0/me/accounts?fields=name,access_token&access_token=#{token}")
    pages_res = Net::HTTP.get_response(pages_uri)
    pages_data = JSON.parse(pages_res.body)
    first_page = pages_data.dig("data", 0)

    unless first_page
      redirect_to root_path, alert: "No Facebook Pages found."
      return
    end

    fb_page_id     = first_page["id"]
    fb_page_token  = first_page["access_token"]

    # Step 2: Get IG Business Account ID
    ig_uri = URI("https://graph.facebook.com/v18.0/#{fb_page_id}?fields=instagram_business_account&access_token=#{token}")
    ig_res = Net::HTTP.get_response(ig_uri)
    ig_data = JSON.parse(ig_res.body)
    ig_user_id = ig_data.dig("instagram_business_account", "id")

    # Save to current user
    user = Current.session.user
    user.update!(
      fb_token: token,
      fb_page_id: fb_page_id,
      fb_page_token: fb_page_token,
      ig_user_id: ig_user_id
    )

    redirect_to post_path, flash: { notice: t('alerts.facebook_linked', profile_name: first_page["name"]) }
  end
end

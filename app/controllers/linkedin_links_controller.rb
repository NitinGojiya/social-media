class LinkedinLinksController < ApplicationController
  LINKEDIN_CLIENT_ID = ENV['LINKEDIN_CLIENT_ID']
  LINKEDIN_CLIENT_SECRET = ENV['LINKEDIN_CLIENT_SECRET']
  REDIRECT_URI = "#{ENV['APP_HOST']}/auth/linkedin/callback"

  def auth
    scope = 'openid profile email w_member_social'
    redirect_to "https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=#{LINKEDIN_CLIENT_ID}&redirect_uri=#{REDIRECT_URI}&scope=#{CGI.escape(scope)}", allow_other_host: true
  end

  def callback
    code = params[:code]
    response = HTTParty.post("https://www.linkedin.com/oauth/v2/accessToken", {
      body: {
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: REDIRECT_URI,
        client_id: LINKEDIN_CLIENT_ID,
        client_secret: LINKEDIN_CLIENT_SECRET
      },
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    })

    access_token = JSON.parse(response.body)["access_token"]
    # session[:linkedin_token] =


      userinfo_response = HTTParty.get("https://api.linkedin.com/v2/userinfo", {
      headers: { "Authorization" => "Bearer #{access_token}" }
    })
    userinfo = userinfo_response.parsed_response
    linkedin_id = userinfo["sub"]
      user = Current.session.user

    user.update!(
    linkedin_token: access_token,
    linkedin_id: linkedin_id
    )
    linkedin_profile = user.linkedin_profiles.create!(
      profile_name:userinfo["name"],
      headline: userinfo["headline"],
      profile_picture_url: userinfo["picture"],
    )
    redirect_to post_path, flash: { notice: t('alerts.linkedin_linked', profile_name: userinfo["name"]) }
  end
end

class LinkedinPostsController < ApplicationController
  LINKEDIN_CLIENT_ID = '77rznug8l4pmrr'
  LINKEDIN_CLIENT_SECRET = 'WPL_AP1.ocAN5q9icvMV3wW1.Eqtqdw=='
  REDIRECT_URI = 'https://5e75be2c9477.ngrok-free.app/auth/linkedin/callback'

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
    session[:linkedin_token] = access_token

    redirect_to linkedin_profile_path
  end

  def profile
    access_token = session[:linkedin_token]

    userinfo_response = HTTParty.get("https://api.linkedin.com/v2/userinfo", {
      headers: { "Authorization" => "Bearer #{access_token}" }
    })

    userinfo = userinfo_response.parsed_response
    session[:linkedin_userinfo] = userinfo  # ✅ Save user info in session

    puts "User Info:"
    puts JSON.pretty_generate(userinfo)

    render json: {
      message: "User info fetched successfully.",
      linkedin_user: userinfo
    }
  end
end

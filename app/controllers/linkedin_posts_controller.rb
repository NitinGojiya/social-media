
class LinkedinPostsController < ApplicationController
  def linkedin_session
    Rails.logger.info "OmniAuth ENV: #{request.env.inspect}"

    auth = request.env['omniauth.auth']
    unless auth
      redirect_to root_path, alert: 'Authentication failed or was not initiated properly.'
      return
    end

    session[:linkedin_token] = auth['credentials']['token']
    session[:linkedin_uid] = auth['uid']
    redirect_to new_post_path, notice: 'Successfully authenticated with LinkedIn!'
  end

  def create
    token = session[:linkedin_token]
    message = params[:post][:content]

    unless token
      redirect_to root_path, alert: "LinkedIn session expired. Please re-authenticate." and return
    end

    user_id = get_linkedin_user_id(token)
    unless user_id
      render plain: "Failed to fetch LinkedIn user ID", status: :unprocessable_entity and return
    end

    uri = URI("https://api.linkedin.com/v2/ugcPosts")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    req = Net::HTTP::Post.new(uri.path, {
      'Authorization' => "Bearer #{token}",
      'Content-Type' => 'application/json',
      'X-Restli-Protocol-Version' => '2.0.0'
    })

    payload = {
      "author": "urn:li:person:#{user_id}",
      "lifecycleState": "PUBLISHED",
      "specificContent": {
        "com.linkedin.ugc.ShareContent": {
          "shareCommentary": {
            "text": message
          },
          "shareMediaCategory": "NONE"
        }
      },
      "visibility": {
        "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
      }
    }

    req.body = payload.to_json

    res = http.request(req)

    if res.code == "201"
      redirect_to root_path, notice: "Successfully posted to LinkedIn!"
    else
      Rails.logger.error "LinkedIn post error: #{res.code} - #{res.body}"
      render plain: "Error posting to LinkedIn: #{res.body}", status: :unprocessable_entity
    end
  end

  private

  def get_linkedin_user_id(token)
    uri = URI("https://api.linkedin.com/v2/me")
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{token}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(req)
    end

    if res.code == "200"
      json = JSON.parse(res.body)
      return json['id'] # Use this as urn:li:person:{id}
    else
      Rails.logger.error "Failed to fetch user ID from LinkedIn: #{res.code} - #{res.body}"
      return nil
    end
  end
end

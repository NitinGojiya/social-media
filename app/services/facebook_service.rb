# app/services/facebook_service.rb
class FacebookService
  def initialize(user)
    @user = user
  end

  def post_to_facebook(image_url, caption)
    uri = URI("https://graph.facebook.com/v18.0/#{@user.fb_page_id}/photos")
    res = Net::HTTP.post_form(uri, {
      url: image_url,
      caption: caption,
      access_token: @user.fb_page_token
    })
    JSON.parse(res.body)
  end

  def post_to_instagram(image_url, caption)
    media_res = Net::HTTP.post_form(
      URI("https://graph.facebook.com/v18.0/#{@user.ig_user_id}/media"),
      { image_url: image_url, caption: caption, access_token: @user.fb_token }
    )
    media_data = JSON.parse(media_res.body)
    creation_id = media_data["id"]

    publish_res = Net::HTTP.post_form(
      URI("https://graph.facebook.com/v18.0/#{@user.ig_user_id}/media_publish"),
      { creation_id: creation_id, access_token: @user.fb_token }
    )
    JSON.parse(publish_res.body)
  end

  def delete_facebook_post(post_id)
    uri = URI("https://graph.facebook.com/v18.0/#{post_id}?access_token=#{@user.fb_page_token}")
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      res = http.request(Net::HTTP::Delete.new(uri))
      JSON.parse(res.body)
    end
  end

  def delete_instagram_post(post_id)
    uri = URI("https://graph.facebook.com/v18.0/#{post_id}?access_token=#{@user.fb_token}")
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      res = http.request(Net::HTTP::Delete.new(uri))
      JSON.parse(res.body)
    end
  end
end

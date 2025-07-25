class PostsController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'

  def new
  end

  def facebook_callback
    auth = request.env['omniauth.auth']
    token = auth['credentials']['token']
    session[:fb_token] = token

    # Step 1: Get Facebook Pages
    pages_uri = URI("https://graph.facebook.com/v18.0/me/accounts?fields=name,access_token&access_token=#{token}")
    pages_res = Net::HTTP.get_response(pages_uri)
    pages_data = JSON.parse(pages_res.body)
    first_page = pages_data.dig("data", 0)

    unless first_page
      redirect_to root_path, alert: "No Facebook Pages found."
      return
    end

    session[:fb_page_id] = first_page["id"]
    session[:fb_page_token] = first_page["access_token"]

    # Step 2: Get IG Business Account ID
    ig_uri = URI("https://graph.facebook.com/v18.0/#{first_page["id"]}?fields=instagram_business_account&access_token=#{token}")
    ig_res = Net::HTTP.get_response(ig_uri)
    ig_data = JSON.parse(ig_res.body)

    session[:ig_user_id] = ig_data.dig("instagram_business_account", "id")
    redirect_to post_path, notice: "Connected to Facebook Page: #{first_page["name"]}"
  end

  def create
    image_url   = params[:image_url]
    caption     = params[:caption]
    post_to_ig  = params[:post_to_ig] == "1"
    post_to_fb  = params[:post_to_fb] == "1"

    fb_token     = session[:fb_token]
    ig_user_id   = session[:ig_user_id]
    fb_page_id   = session[:fb_page_id]
    fb_page_token = session[:fb_page_token]

    if image_url.blank? || (!post_to_ig && !post_to_fb)
      render json: { error: "Please select platform and provide an image URL." }, status: :unprocessable_entity
      return
    end

    results = []

    if post_to_ig && ig_user_id && fb_token
      ig_res = post_to_instagram(ig_user_id, fb_token, image_url, caption)
      results << ig_res[:message]
    end

    if post_to_fb && fb_page_id && fb_page_token
      fb_res = post_to_facebook(fb_page_id, fb_page_token, image_url, caption)
      results << fb_res[:message]
    end

    render json: { success: true, message: results.join(" | ") }, status: :ok
  end

  private

  def post_to_instagram(ig_user_id, token, image_url, caption)
    uri = URI("https://graph.facebook.com/v18.0/#{ig_user_id}/media")
    res = Net::HTTP.post_form(uri, {
      image_url: image_url,
      caption: caption,
      access_token: token
    })

    res_data = JSON.parse(res.body)
    return { error: true, message: res_data["error"]["message"] } if res_data["error"]

    creation_id = res_data["id"]
    publish_uri = URI("https://graph.facebook.com/v18.0/#{ig_user_id}/media_publish")
    publish_res = Net::HTTP.post_form(publish_uri, {
      creation_id: creation_id,
      access_token: token
    })

    publish_data = JSON.parse(publish_res.body)
    if publish_data["error"]
      { error: true, message: publish_data["error"]["message"] }
    else
      { error: false, message: "Instagram post published! ID: #{publish_data["id"]}" }
    end
  end

  def post_to_facebook(page_id, token, image_url, caption)
    uri = URI("https://graph.facebook.com/v18.0/#{page_id}/photos")
    res = Net::HTTP.post_form(uri, {
      url: image_url,
      caption: caption,
      access_token: token
    })

    res_data = JSON.parse(res.body)
    if res_data["error"]
      { error: true, message: res_data["error"]["message"] }
    else
      { error: false, message: "Facebook post published! ID: #{res_data["post_id"] || res_data["id"]}" }
    end
  end

end

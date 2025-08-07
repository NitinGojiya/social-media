class FacebookService
  def initialize(user)
    @user = user
  end

  # Support single or multiple images
  def post_to_facebook(image_urls, caption)
    image_urls = Array(image_urls)

    if image_urls.size == 1
      # Simple single image post
      uri = URI("https://graph.facebook.com/v18.0/#{@user.fb_page_id}/photos")
      res = Net::HTTP.post_form(uri, {
        url: image_urls.first,
        caption: caption,
        access_token: @user.fb_page_token
      })
      return JSON.parse(res.body)
    else
      # Create multiple unpublished photos
      photo_ids = image_urls.map do |image_url|
        uri = URI("https://graph.facebook.com/v18.0/#{@user.fb_page_id}/photos")
        res = Net::HTTP.post_form(uri, {
          url: image_url,
          published: false,
          access_token: @user.fb_page_token
        })
        JSON.parse(res.body)["id"]
      end.compact

      # Create a post with all images as attached_media
      uri = URI("https://graph.facebook.com/v18.0/#{@user.fb_page_id}/feed")
      form_data = {
        message: caption,
        access_token: @user.fb_page_token
      }

      photo_ids.each_with_index do |id, index|
        form_data["attached_media[#{index}]"] = { media_fbid: id }.to_json
      end

      res = Net::HTTP.post_form(uri, form_data)
      JSON.parse(res.body)
    end
  end

  def post_to_instagram(image_urls, caption)
  image_urls = Array(image_urls)

  if image_urls.size == 1
    return post_single_instagram_image(image_urls.first, caption)
  else
    # Upload each image as carousel item
    creation_ids = image_urls.map do |url|
      res = Net::HTTP.post_form(
        URI("https://graph.facebook.com/v18.0/#{@user.ig_user_id}/media"),
        {
          image_url: url,
          is_carousel_item: true,
          access_token: @user.fb_token
        }
      )
      JSON.parse(res.body)["id"]
    end.compact

    # Build the carousel post
    uri = URI("https://graph.facebook.com/v18.0/#{@user.ig_user_id}/media")
    req = Net::HTTP::Post.new(uri)
    req.set_form_data({
      caption: caption,
      media_type: "CAROUSEL",
      access_token: @user.fb_token
    }.merge(
      creation_ids.each_with_index.map { |id, i| ["children[#{i}]", id] }.to_h
    ))

    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = true
    res = http.request(req)
    container_id = JSON.parse(res.body)["id"]

    # Publish the carousel
    publish_res = Net::HTTP.post_form(
      URI("https://graph.facebook.com/v18.0/#{@user.ig_user_id}/media_publish"),
      {
        creation_id: container_id,
        access_token: @user.fb_token
      }
    )
    JSON.parse(publish_res.body)
  end
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

  private

  def post_single_instagram_image(image_url, caption)
    media_res = Net::HTTP.post_form(
      URI("https://graph.facebook.com/v18.0/#{@user.ig_user_id}/media"),
      {
        image_url: image_url,
        caption: caption,
        access_token: @user.fb_token
      }
    )
    media_data = JSON.parse(media_res.body)
    creation_id = media_data["id"]

    publish_res = Net::HTTP.post_form(
      URI("https://graph.facebook.com/v18.0/#{@user.ig_user_id}/media_publish"),
      {
        creation_id: creation_id,
        access_token: @user.fb_token
      }
    )
    JSON.parse(publish_res.body)
  end
end

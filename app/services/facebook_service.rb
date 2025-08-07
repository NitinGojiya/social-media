class FacebookService
  def initialize(user)
    @user = user
  end

  # Support single or multiple images
  def post_to_facebook(media_urls, caption)
    media_urls = Array(media_urls)

    if media_urls.size == 1
      media_url = media_urls.first
      if media_url =~ /\.(mp4|mov)$/i
        # VIDEO post
        uri = URI("https://graph.facebook.com/v18.0/#{@user.fb_page_id}/videos")
        res = Net::HTTP.post_form(uri, {
          file_url: media_url,
          description: caption,
          access_token: @user.fb_page_token
        })
        return JSON.parse(res.body)
      else
        # IMAGE post
        uri = URI("https://graph.facebook.com/v18.0/#{@user.fb_page_id}/photos")
        res = Net::HTTP.post_form(uri, {
          url: media_url,
          caption: caption,
          access_token: @user.fb_page_token
        })
        return JSON.parse(res.body)
      end
    else
      # Multiple images only (videos not supported in multi-upload)
      photo_ids = media_urls.map do |url|
        next if url =~ /\.(mp4|mov)$/i # skip videos
        uri = URI("https://graph.facebook.com/v18.0/#{@user.fb_page_id}/photos")
        res = Net::HTTP.post_form(uri, {
          url: url,
          published: false,
          access_token: @user.fb_page_token
        })
        JSON.parse(res.body)["id"]
      end.compact

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

  def post_to_instagram(media_urls, caption)
  media_urls = Array(media_urls)

  if media_urls.size == 1
    url = media_urls.first

    if url =~ /\.(mp4|mov)$/i
      return post_instagram_reel(url, caption)
    else
      return post_single_instagram_image(url, caption)
    end
  else
    # Carousel only supports images
    if media_urls.any? { |url| url =~ /\.(mp4|mov)$/i }
      return { error: "Instagram does not support video in carousel posts." }
    end

    creation_ids = media_urls.map do |url|
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

    if creation_ids.empty?
      return { error: "No valid images for Instagram carousel post." }
    end

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

 def post_instagram_reel(video_url, caption)
  Rails.logger.info "Uploading Reel to IG: #{video_url}"

  # Step 1: Download the video locally
  original_tmp_path = Rails.root.join("tmp", "#{SecureRandom.uuid}_original.mp4").to_s
  File.open(original_tmp_path, "wb") do |file|
    URI.open(video_url) { |read_file| file.write(read_file.read) }
  end

  # Step 2: Convert it
  converted_path = VideoProcessorHelper.convert_to_instagram_reel(original_tmp_path)
  return { error: "Video conversion failed" } unless converted_path && File.exist?(converted_path)

  # Step 3: Upload the converted file to your app/server
  uploaded_file = ActiveStorage::Blob.create_and_upload!(
    io: File.open(converted_path),
    filename: "converted_video.mp4",
    content_type: "video/mp4"
  )

  converted_url = Rails.application.routes.url_helpers.rails_blob_url(
    uploaded_file,
    only_path: false,  # ensure full URL for Instagram
    host: ENV['APP_HOST']  # Use your app's host here
  )

  # Step 4: Create IG media container
  creation_res = Net::HTTP.post_form(
    URI("https://graph.facebook.com/v18.0/#{@user.ig_user_id}/media"),
    {
      video_url: converted_url,
      caption: caption,
      media_type: "REELS",
      access_token: @user.fb_token
    }
  )

  creation_data = JSON.parse(creation_res.body)
  creation_id = creation_data["id"]

  unless creation_id
    Rails.logger.error("Instagram REEL Creation Failed: #{creation_data}")
    return { error: creation_data["error"] || "Reel creation failed" }
  end

  # Step 5: Wait for media to be ready
  # Step 5: Wait for media to be ready
20.times do
  status_res = Net::HTTP.get(
    URI("https://graph.facebook.com/v18.0/#{creation_id}?fields=status_code&access_token=#{@user.fb_token}")
  )
  status_data = JSON.parse(status_res)

  if status_data["status_code"] == "FINISHED"
    break
  else
    Rails.logger.info("Waiting for media to finish processing... Status: #{status_data["status_code"]}")
    sleep 5
  end
end

  # Step 6: Publish the Reel
  publish_res = Net::HTTP.post_form(
    URI("https://graph.facebook.com/v18.0/#{@user.ig_user_id}/media_publish"),
    {
      creation_id: creation_id,
      access_token: @user.fb_token
    }
  )



  publish_data = JSON.parse(publish_res.body)

  unless publish_data["id"]
    Rails.logger.error("Instagram REEL Publish Failed: #{publish_data}")
  end

  publish_data
ensure
  File.delete(original_tmp_path) if File.exist?(original_tmp_path)
  File.delete(converted_path) if converted_path && File.exist?(converted_path)
end


end

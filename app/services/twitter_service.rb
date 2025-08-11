require 'net/http'
require 'uri'
require 'net/http/post/multipart'  # for multipart upload
require 'ostruct'
require 'stringio'
require 'tempfile'
require 'json'

class TwitterService
  MAX_IMAGE_SIZE = 5 * 1024 * 1024    # 5MB max for images
  MAX_VIDEO_SIZE = 512 * 1024 * 1024  # 512MB max for videos

  ALLOWED_CONTENT_TYPES = [
    "image/jpeg",
    "image/png",
    "image/gif",
    "video/mp4"
  ]

  def initialize(twitter_profile)
    # OAuth 1.0a for media upload
    @consumer = OAuth::Consumer.new(
      ENV["TWITTER_API_KEY"],
      ENV["TWITTER_API_SECRET"],
      site: "https://upload.twitter.com",
      scheme: :header
    )
    @access_token = OAuth::AccessToken.new(
      @consumer,
      twitter_profile.token,
      twitter_profile.secret
    )
    @nickname = twitter_profile.nickname

    # OAuth 2.0 Bearer token for v2 tweet creation
    @bearer_token = twitter_profile.bearer_token || ENV["TWITTER_BEARER_TOKEN"]
  end

  def upload_media(file)
    validate_file!(file)

    if file.content_type.start_with?("video")
      converted_file = convert_video_to_twitter_format(file)
      begin
        upload_video_chunked(converted_file)
      ensure
        converted_file.tempfile.close
        converted_file.tempfile.unlink
      end
    else
      upload_image_simple(file)
    end
  end

  def post_tweet(caption, media_files = [])
    images = media_files.select { |f| f.content_type.start_with?("image") }
    videos = media_files.select { |f| f.content_type.start_with?("video") }

    if videos.any? && images.any?
      return OpenStruct.new(success?: false, error: "Cannot attach both images and videos to the same tweet.")
    end

    if images.size > 4
      return OpenStruct.new(success?: false, error: "You can only attach up to 4 images.")
    end

    if videos.size > 1
      return OpenStruct.new(success?: false, error: "You can only attach 1 video.")
    end

    begin
      media_ids = (images + videos).map { |file| upload_media(file) }
    rescue => e
      return OpenStruct.new(success?: false, error: "Media upload error: #{e.message}")
    end

    uri = URI("https://api.twitter.com/2/tweets")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    body = {
      text: caption.presence || "Posted via API",
      media: media_ids.any? ? { media_ids: media_ids } : nil
    }.compact

    req = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
    req.body = body.to_json

    consumer_v2 = OAuth::Consumer.new(
      ENV["TWITTER_API_KEY"],
      ENV["TWITTER_API_SECRET"],
      site: "https://api.twitter.com",
      scheme: :header
    )
    access_token_v2 = OAuth::AccessToken.new(
      consumer_v2,
      @access_token.token,
      @access_token.secret
    )
    consumer_v2.sign!(req, access_token_v2)

    response = http.request(req)
    Rails.logger.error "[Twitter Tweet v2] #{response.code} #{response.body}"

    if response.code.to_i == 201
      tweet_id = JSON.parse(response.body).dig("data", "id")
      OpenStruct.new(success?: true, url: "https://twitter.com/#{@nickname}/status/#{tweet_id}")
    else
      error_msg = parse_twitter_error(response.body)
      OpenStruct.new(success?: false, error: error_msg)
    end
  end

  def delete_tweet(tweet_id)
  # Use the correct API base URL
  consumer = OAuth::Consumer.new(
    ENV["TWITTER_API_KEY"],
    ENV["TWITTER_API_SECRET"],
    site: "https://api.twitter.com",
    scheme: :header
  )

  # Create access token with user's credentials
  access_token = OAuth::AccessToken.new(
    consumer,
    @access_token.token,  # User's OAuth token
    @access_token.secret  # User's OAuth secret
  )

  uri = URI("https://api.twitter.com/1.1/statuses/destroy/#{tweet_id}.json")
  req = Net::HTTP::Post.new(uri.request_uri)
  req["Content-Type"] = "application/x-www-form-urlencoded"

  # Sign with correct credentials
  consumer.sign!(req, access_token)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  response = http.request(req)

  if response.code.to_i == 200
    true
  else
    Rails.logger.error "[Twitter Delete] #{response.code} #{response.body}"
    false
  end
end




  private

  def validate_file!(file)
    max_size = file.content_type.start_with?("video") ? MAX_VIDEO_SIZE : MAX_IMAGE_SIZE

    if file.size > max_size
      raise "File too large. Max size is #{max_size / (1024 * 1024)}MB."
    end

    unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
      raise "Invalid file type. Allowed: #{ALLOWED_CONTENT_TYPES.join(', ')}"
    end
  end

  def convert_video_to_twitter_format(file)
    converted_tempfile = Tempfile.new(['converted', '.mp4'])
    converted_tempfile.binmode

    input_path = file.tempfile.path
    output_path = converted_tempfile.path

    ffmpeg_command = [
      'ffmpeg', '-i', input_path,
      '-c:v', 'libx264', '-profile:v', 'baseline', '-level', '3.0', '-pix_fmt', 'yuv420p',
      '-c:a', 'aac', '-b:a', '128k',
      '-movflags', '+faststart',
      '-y', output_path
    ]

    # Run ffmpeg
    success = system(*ffmpeg_command)

    unless success && File.size?(output_path)
      raise "Video conversion failed or produced empty output."
    end

    # Wrap converted tempfile to mimic uploaded file interface
    OpenStruct.new(
      tempfile: converted_tempfile,
      content_type: 'video/mp4',
      original_filename: "converted_#{file.original_filename}",
      size: File.size(output_path)
    )
  end

  def upload_image_simple(file)
    uri = URI.parse("https://upload.twitter.com/1.1/media/upload.json")
    File.open(file.tempfile, "rb") do |f|
      req = Net::HTTP::Post::Multipart.new(
        uri.path,
        "media" => UploadIO.new(f, file.content_type, file.original_filename)
      )
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      @consumer.sign!(req, @access_token)
      response = http.request(req)

      Rails.logger.error "[Twitter Upload] #{response.code} #{response.body}"

      unless response.code.to_i == 200
        raise "Media upload failed: #{parse_twitter_error(response.body)}"
      end

      JSON.parse(response.body)["media_id_string"]
    end
  end

  def upload_video_chunked(file)
    uri = URI.parse("https://upload.twitter.com/1.1/media/upload.json")
    total_bytes = file.size
    media_type = file.content_type

    # 1. INIT
    init_req = Net::HTTP::Post.new(uri.path)
    init_req.set_form_data(
      "command" => "INIT",
      "media_type" => media_type,
      "total_bytes" => total_bytes,
      "media_category" => "tweet_video"
    )
    @consumer.sign!(init_req, @access_token)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    init_res = http.request(init_req)
    unless [200, 201, 202].include?(init_res.code.to_i)
      raise "INIT failed: #{init_res.body}"
    end
    media_id = JSON.parse(init_res.body)["media_id_string"]

    # 2. APPEND (upload chunks)
    segment_index = 0
    File.open(file.tempfile, "rb") do |video_file|
      until video_file.eof?
        chunk = video_file.read(5 * 1024 * 1024) # 5MB chunk
        append_req = Net::HTTP::Post::Multipart.new(
          uri.path,
          "command" => "APPEND",
          "media_id" => media_id,
          "segment_index" => segment_index,
          "media" => UploadIO.new(StringIO.new(chunk), media_type, file.original_filename)
        )
        @consumer.sign!(append_req, @access_token)
        append_res = http.request(append_req)
        unless append_res.code.to_i == 204
          raise "APPEND failed: #{append_res.body}"
        end
        segment_index += 1
      end
    end

    # 3. FINALIZE
    finalize_req = Net::HTTP::Post.new(uri.path)
    finalize_req.set_form_data(
      "command" => "FINALIZE",
      "media_id" => media_id
    )
    @consumer.sign!(finalize_req, @access_token)
    finalize_res = http.request(finalize_req)
    unless [200, 201].include?(finalize_res.code.to_i)
      raise "FINALIZE failed: #{finalize_res.body}"
    end

    # 4. Wait for processing if video
    wait_for_processing(media_id)

    media_id
  end

 def wait_for_processing(media_id)
  uri = URI("https://upload.twitter.com/1.1/media/upload.json")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  loop do
    params = { command: "STATUS", media_id: media_id }
    uri.query = URI.encode_www_form(params)
    status_req = Net::HTTP::Get.new(uri)

    @consumer.sign!(status_req, @access_token)
    status_res = http.request(status_req)

    unless status_res.code.to_i == 200
      raise "STATUS check failed: #{status_res.body}"
    end

    json = JSON.parse(status_res.body)

    if json["processing_info"].nil? || json["processing_info"]["state"] == "succeeded"
      break
    elsif json["processing_info"]["state"] == "failed"
      error = json["processing_info"]["error"]
      raise "Video processing failed: #{error['name']} - #{error['message']}"
    else
      sleep_seconds = json["processing_info"]["check_after_secs"] || 5
      sleep sleep_seconds
    end
  end
end


  def parse_twitter_error(body)
    json = JSON.parse(body) rescue nil
    if json && json["errors"]
      json["errors"].map { |e| "#{e['code']}: #{e['message']}" }.join(", ")
    elsif json && json["detail"]
      json["detail"]
    else
      body.to_s
    end
  end
end

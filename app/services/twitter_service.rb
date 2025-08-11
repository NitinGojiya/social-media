require 'net/http'
require 'uri'
require 'net/http/post/multipart'  # this is the important one
require 'ostruct'
class TwitterService
  MAX_FILE_SIZE = 5 * 1024 * 1024 # 5MB
  ALLOWED_CONTENT_TYPES = ["image/jpeg", "image/png", "image/gif"]

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
    uri = URI.parse("https://upload.twitter.com/1.1/media/upload.json")

    File.open(file.tempfile, "rb") do |f|
      req = Net::HTTP::Post::Multipart.new(
        uri.path,
        "media" => UploadIO.new(f, file.content_type, file.original_filename)
      )
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      @consumer.sign!(req, @access_token) # OAuth1 sign
      response = http.request(req)

      Rails.logger.error "[Twitter Upload] #{response.code} #{response.body}"

      unless response.code.to_i == 200
        raise "Media upload failed: #{parse_twitter_error(response.body)}"
      end

      JSON.parse(response.body)["media_id_string"]
    end
  end

  def post_tweet(caption, media_files = [])
  media_ids = media_files.map { |file| upload_media(file) }

  uri = URI("https://api.twitter.com/2/tweets")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  body = {
    text: caption.presence || "Posted via API",
    media: media_ids.any? ? { media_ids: media_ids } : nil
  }.compact

  req = Net::HTTP::Post.new(uri.path, { "Content-Type" => "application/json" })
  req.body = body.to_json

  # Sign with OAuth1 user credentials (user context)
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


  private

  def validate_file!(file)
    if file.size > MAX_FILE_SIZE
      raise "File too large. Max size is #{MAX_FILE_SIZE / (1024 * 1024)}MB."
    end
    unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
      raise "Invalid file type. Allowed: #{ALLOWED_CONTENT_TYPES.join(', ')}"
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

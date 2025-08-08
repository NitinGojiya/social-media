# app/services/twitter_service.rb
require 'ostruct'
class TwitterService
  def initialize(twitter_profile)
    @consumer = OAuth::Consumer.new(
      ENV["TWITTER_API_KEY"],
      ENV["TWITTER_API_SECRET"],
      site: "https://api.twitter.com",
      scheme: :header
    )
    @access_token = OAuth::AccessToken.new(
      @consumer,
      twitter_profile.token,
      twitter_profile.secret
    )
    @nickname = twitter_profile.nickname
  end

  def post_tweet(caption)
    response = @access_token.post(
      "https://api.twitter.com/2/tweets",
      { text: caption.presence || "Posted via API" }.to_json,
      { "Content-Type" => "application/json" }
    )

    if response.code.to_i == 201
      tweet_id = JSON.parse(response.body).dig("data", "id")
      OpenStruct.new(success?: true, url: "https://twitter.com/#{@nickname}/status/#{tweet_id}")
    else
      error_msg = JSON.parse(response.body)["detail"] rescue "Unknown error"
      OpenStruct.new(success?: false, error: error_msg)
    end
  rescue => e
    OpenStruct.new(success?: false, error: e.message)
  end
end

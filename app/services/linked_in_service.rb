# app/services/linkedin_service.rb
class LinkedInService
  def initialize(user)
    @user = user
    @access_token = user.linkedin_token
    @linkedin_id = user.linkedin_id
  end

  def create_post(image_files:, caption:)
    image_files = Array(image_files)
    raise "Maximum 9 images allowed" if image_files.size > 9

    author_urn = "urn:li:person:#{@linkedin_id}"
    media_assets = image_files.map do |file|
      asset, upload_url = register_upload(author_urn)
      upload_image(upload_url, file)
      { status: "READY", media: asset }
    end

    create_ugc_post(author_urn, media_assets, caption)
  end


  def delete_post(linkedin_post_urn)
    post_id = linkedin_post_urn.split(":").last
    HTTParty.delete(
      "https://api.linkedin.com/v2/shares/#{post_id}",
      headers: auth_headers
    )
  end

  private

  def register_upload(author_urn)
    response = HTTParty.post(
      "https://api.linkedin.com/v2/assets?action=registerUpload",
      headers: auth_headers.merge("Content-Type" => "application/json"),
      body: {
        registerUploadRequest: {
          owner: author_urn,
          recipes: ["urn:li:digitalmediaRecipe:feedshare-image"],
          serviceRelationships: [
            { identifier: "urn:li:userGeneratedContent", relationshipType: "OWNER" }
          ]
        }
      }.to_json
    )
    upload_info = response.parsed_response
    [
      upload_info["value"]["asset"],
      upload_info["value"]["uploadMechanism"]["com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest"]["uploadUrl"]
    ]
  end

  def upload_image(upload_url, file)
    HTTParty.put(
      upload_url,
      headers: { "Content-Type" => file.content_type },
      body: file.read
    )
  end

  def create_ugc_post(author_urn, media_assets, caption)
  response = HTTParty.post(
    "https://api.linkedin.com/v2/ugcPosts",
    headers: auth_headers.merge("Content-Type" => "application/json"),
    body: {
      author: author_urn,
      lifecycleState: "PUBLISHED",
      specificContent: {
        "com.linkedin.ugc.ShareContent": {
          shareCommentary: { text: caption },
          shareMediaCategory: "IMAGE",
          media: media_assets
        }
      },
      visibility: { "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC" }
    }.to_json
  )

  raise "LinkedIn post failed: #{response.body}" unless response.success?
  JSON.parse(response.body)
end



  def auth_headers
    {
      "Authorization" => "Bearer #{@access_token}",
      "X-Restli-Protocol-Version" => "2.0.0"
    }
  end
end

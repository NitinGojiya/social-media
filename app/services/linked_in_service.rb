# app/services/linkedin_service.rb
class LinkedInService
  def initialize(user)
    @user = user
    @access_token = user.linkedin_token
    @linkedin_id = user.linkedin_id
  end

  def create_post(image_file:, caption:)
    author_urn = "urn:li:person:#{@linkedin_id}"
    asset, upload_url = register_upload(author_urn)
    upload_image(upload_url, image_file)
    create_ugc_post(author_urn, asset, caption)
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

  def create_ugc_post(author_urn, asset, caption)
    HTTParty.post(
      "https://api.linkedin.com/v2/ugcPosts",
      headers: auth_headers.merge("Content-Type" => "application/json"),
      body: {
        author: author_urn,
        lifecycleState: "PUBLISHED",
        specificContent: {
          "com.linkedin.ugc.ShareContent": {
            shareCommentary: { text: caption },
            shareMediaCategory: "IMAGE",
            media: [{ status: "READY", media: asset }]
          }
        },
        visibility: { "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC" }
      }.to_json
    )
  end

  def auth_headers
    {
      "Authorization" => "Bearer #{@access_token}",
      "X-Restli-Protocol-Version" => "2.0.0"
    }
  end
end

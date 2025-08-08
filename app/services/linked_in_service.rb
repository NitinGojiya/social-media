# app/services/linkedin_service.rb
class LinkedInService
  def initialize(user)
    @user = user
    @access_token = user.linkedin_token
    @linkedin_id = user.linkedin_id
  end

  def create_post(image_files:, caption:)
    files = Array(image_files)
    raise "Maximum 9 images or 1 video allowed" if files.size > 9

    author_urn = "urn:li:person:#{@linkedin_id}"

    first_file = files.first
    file_content_type = if first_file.respond_to?(:content_type)
                          first_file.content_type
                        else
                          first_file[:content_type]
                        end

    if file_content_type.start_with?("video/")
      raise "Only one video allowed per post" if files.size > 1

      asset, upload_url = register_upload(author_urn, type: :video)
      upload_video(upload_url, first_file)
      media_asset = { status: "READY", media: asset }
      create_video_post(author_urn, media_asset, caption)
    else
      media_assets = files.map do |file|
        asset, upload_url = register_upload(author_urn, type: :image)
        upload_image(upload_url, file)
        { status: "READY", media: asset }
      end
      create_ugc_post(author_urn, media_assets, caption)
    end
  end

  def delete_post(linkedin_post_urn)
    post_id = linkedin_post_urn.split(":").last
    HTTParty.delete(
      "https://api.linkedin.com/v2/shares/#{post_id}",
      headers: auth_headers
    )
  end

  private

  def register_upload(author_urn, type:)
    recipe = type == :video ? "urn:li:digitalmediaRecipe:feedshare-video" : "urn:li:digitalmediaRecipe:feedshare-image"

    response = HTTParty.post(
      "https://api.linkedin.com/v2/assets?action=registerUpload",
      headers: auth_headers.merge("Content-Type" => "application/json"),
      body: {
        registerUploadRequest: {
          owner: author_urn,
          recipes: [recipe],
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

  def create_video_post(author_urn, media_asset, caption)
    response = HTTParty.post(
      "https://api.linkedin.com/v2/ugcPosts",
      headers: auth_headers.merge("Content-Type" => "application/json"),
      body: {
        author: author_urn,
        lifecycleState: "PUBLISHED",
        specificContent: {
          "com.linkedin.ugc.ShareContent": {
            shareCommentary: { text: caption },
            shareMediaCategory: "VIDEO",
            media: [media_asset]
          }
        },
        visibility: {
          "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
        }
      }.to_json
    )

    raise "LinkedIn video post failed: #{response.body}" unless response.success?
    JSON.parse(response.body)
  end

  def upload_video(upload_url, file)
    HTTParty.put(
      upload_url,
      headers: {
        "Content-Type" => get_file_content_type(file)
      },
      body: get_file_body(file)
    )
  end


  def upload_image(upload_url, file)
    HTTParty.put(
      upload_url,
      headers: { "Content-Type" => get_file_content_type(file) },
      body: get_file_body(file)
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

  def get_file_body(file)
    if file.respond_to?(:read)
      file.rewind
      file.read
    elsif file[:io].respond_to?(:read)
      file[:io].rewind
      file[:io].read
    else
      raise "Invalid file format for upload"
    end
  end

  def get_file_content_type(file)
    file.respond_to?(:content_type) ? file.content_type : file[:content_type]
  end
end

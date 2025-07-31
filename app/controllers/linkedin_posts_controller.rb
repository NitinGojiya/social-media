class LinkedinPostsController < ApplicationController
  LINKEDIN_CLIENT_ID = '77rznug8l4pmrr'
  LINKEDIN_CLIENT_SECRET = 'WPL_AP1.ocAN5q9icvMV3wW1.Eqtqdw=='
  REDIRECT_URI = "https://31eb8ff3acd8.ngrok-free.app/auth/linkedin/callback"

  def auth
    scope = 'openid profile email w_member_social'
    redirect_to "https://www.linkedin.com/oauth/v2/authorization?response_type=code&client_id=#{LINKEDIN_CLIENT_ID}&redirect_uri=#{REDIRECT_URI}&scope=#{CGI.escape(scope)}", allow_other_host: true
  end

  def callback
    code = params[:code]

    response = HTTParty.post("https://www.linkedin.com/oauth/v2/accessToken", {
      body: {
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: REDIRECT_URI,
        client_id: LINKEDIN_CLIENT_ID,
        client_secret: LINKEDIN_CLIENT_SECRET
      },
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' }
    })

    access_token = JSON.parse(response.body)["access_token"]
    session[:linkedin_token] = access_token

    redirect_to linkedin_profile_path
  end

  def profile
    access_token = session[:linkedin_token]

    userinfo_response = HTTParty.get("https://api.linkedin.com/v2/userinfo", {
      headers: { "Authorization" => "Bearer #{access_token}" }
    })

    userinfo = userinfo_response.parsed_response
    session[:linkedin_userinfo] = userinfo  # ✅ Save user info in session

    puts "User Info:"
    puts JSON.pretty_generate(userinfo)

    render json: {
      message: "User info fetched successfully.",
      linkedin_user: userinfo
    }
  end
  def post_to_linkedin
  access_token = session[:linkedin_token]
  userinfo = session[:linkedin_userinfo]

  unless access_token && userinfo
    render json: { error: "Missing access token or user info" }, status: :unauthorized and return
  end

  linkedin_id = userinfo["sub"]
  author_urn = "urn:li:person:#{linkedin_id}"

  post_body = {
    "author": author_urn,
    "lifecycleState": "PUBLISHED",
    "specificContent": {
      "com.linkedin.ugc.ShareContent": {
        "shareCommentary": {
          "text": "Hello LinkedIn! 🎉 This is my first post via the LinkedIn API."
        },
        "shareMediaCategory": "NONE"
      }
    },
    "visibility": {
      "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
    }
  }

  response = HTTParty.post("https://api.linkedin.com/v2/ugcPosts",
    headers: {
      "Authorization" => "Bearer #{access_token}",
      "X-Restli-Protocol-Version" => "2.0.0",
      "Content-Type" => "application/json"
    },
    body: post_body.to_json
  )

  if response.success?
    render json: { message: "Post created successfully!", response: response.parsed_response }
  else
    render json: { error: "Failed to post", response: response.parsed_response }, status: :unprocessable_entity
  end
end

def post_with_image
  access_token = session[:linkedin_token]
  userinfo = session[:linkedin_userinfo]

  unless access_token && userinfo
    render json: { error: "Missing access token or user info" }, status: :unauthorized and return
  end

  linkedin_id = userinfo["sub"]
  author_urn = "urn:li:person:#{linkedin_id}"

  # STEP 1: Register the image upload
  register_response = HTTParty.post("https://api.linkedin.com/v2/assets?action=registerUpload", {
    headers: {
      "Authorization" => "Bearer #{access_token}",
      "Content-Type" => "application/json"
    },
    body: {
      registerUploadRequest: {
        owner: author_urn,
        recipes: ["urn:li:digitalmediaRecipe:feedshare-image"],
        serviceRelationships: [
          {
            identifier: "urn:li:userGeneratedContent",
            relationshipType: "OWNER"
          }
        ]
      }
    }.to_json
  })

  unless register_response.success?
    render json: { error: "Failed to register image upload", response: register_response.parsed_response }, status: :unprocessable_entity and return
  end

  upload_info = register_response.parsed_response
  upload_url = upload_info["value"]["uploadMechanism"]["com.linkedin.digitalmedia.uploading.MediaUploadHttpRequest"]["uploadUrl"]
  asset = upload_info["value"]["asset"]

  # STEP 2: Upload image binary (using image path from your server or static path)
  # image_path = Rails.root.join("/uploads/1a4d7e29-5185-4bc2-9035-0ca1efe58641_CompressJPEG.Online_img_512x512_-removebg-preview.png") # change this path
  image_path = Rails.root.join("public", "uploads", "1a4d7e29-5185-4bc2-9035-0ca1efe58641_CompressJPEG.Online_img_512x512_-removebg-preview.png")

  image_data = File.read(image_path)

  upload_result = HTTParty.put(upload_url,
    headers: { "Content-Type" => "image/jpeg" },
    body: image_data
  )

  unless upload_result.success?
    render json: { error: "Failed to upload image", response: upload_result.parsed_response }, status: :unprocessable_entity and return
  end

  # STEP 3: Create post with image
  post_body = {
    author: author_urn,
    lifecycleState: "PUBLISHED",
    specificContent: {
      "com.linkedin.ugc.ShareContent": {
        shareCommentary: {
          text: "Posting an image to LinkedIn via API! 📷"
        },
        shareMediaCategory: "IMAGE",
        media: [
          {
            status: "READY",
            media: asset
          }
        ]
      }
    },
    visibility: {
      "com.linkedin.ugc.MemberNetworkVisibility": "PUBLIC"
    }
  }

  post_response = HTTParty.post("https://api.linkedin.com/v2/ugcPosts",
    headers: {
      "Authorization" => "Bearer #{access_token}",
      "X-Restli-Protocol-Version" => "2.0.0",
      "Content-Type" => "application/json"
    },
    body: post_body.to_json
  )

  if post_response.success?
    render json: { message: "Image post created!", response: post_response.parsed_response }
  else
    render json: { error: "Failed to post with image", response: post_response.parsed_response }, status: :unprocessable_entity
  end
end


end

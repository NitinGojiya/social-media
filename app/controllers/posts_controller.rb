class PostsController < ApplicationController
  require 'net/http'
  require 'uri'
  require 'json'

  after_action :delete_uploaded_file, only: [:create]

  def new
  end

  def facebook_callback
    auth = request.env['omniauth.auth']
    token = auth['credentials']['token']

    # Step 1: Get Facebook Pages
    pages_uri = URI("https://graph.facebook.com/v18.0/me/accounts?fields=name,access_token&access_token=#{token}")
    pages_res = Net::HTTP.get_response(pages_uri)
    pages_data = JSON.parse(pages_res.body)
    first_page = pages_data.dig("data", 0)

    unless first_page
      redirect_to root_path, alert: "No Facebook Pages found."
      return
    end

    fb_page_id     = first_page["id"]
    fb_page_token  = first_page["access_token"]

    # Step 2: Get IG Business Account ID
    ig_uri = URI("https://graph.facebook.com/v18.0/#{fb_page_id}?fields=instagram_business_account&access_token=#{token}")
    ig_res = Net::HTTP.get_response(ig_uri)
    ig_data = JSON.parse(ig_res.body)
    ig_user_id = ig_data.dig("instagram_business_account", "id")

    # Save to current user
    user = Current.session.user
    user.update!(
      fb_token: token,
      fb_page_id: fb_page_id,
      fb_page_token: fb_page_token,
      ig_user_id: ig_user_id
    )

    redirect_to post_path, notice: "Connected to Facebook Page: #{first_page["name"]}"
  end


  def create
    uploaded_file  = params[:image_file]
    image_url      = params[:image_url]
    caption        = params[:caption]
    post_to_ig     = params[:post_to_ig] == "1"
    post_to_fb     = params[:post_to_fb] == "1"
    selected_date  = params[:date].to_date rescue Date.today

    user = Current.session.user
    fb_token       = user.fb_token
    ig_user_id     = user.ig_user_id
    fb_page_id     = user.fb_page_id
    fb_page_token  = user.fb_page_token

    if uploaded_file.present?
      image_url = upload_image_and_get_url(uploaded_file)
      uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
    end

    if image_url.blank? || (!post_to_ig && !post_to_fb)
      render json: { error: "Please select a platform and provide an image." }, status: :unprocessable_entity
      return
    end

    user = Current.session.user
    post = user.posts.create!(
      caption: caption,
      ig: post_to_ig ? 1 : 0,
      fb: post_to_fb ? 1 : 0,
      scheduled_at: selected_date,
      status: selected_date == Date.today ? 2 : 1
    )

    if uploaded_file.present? && uploaded_file.respond_to?(:tempfile) && uploaded_file.size > 0
      post.photo.attach(
        io: uploaded_file.tempfile,
        filename: uploaded_file.original_filename,
        content_type: uploaded_file.content_type
      )
    end

    results = []
    if selected_date == Date.today

     if post_to_ig && ig_user_id && fb_token
        ig_res = post_to_instagram(ig_user_id, fb_token, image_url, caption)
        post.update(ig_post_id: ig_res[:id]) if ig_res[:id]
        results << ig_res[:message]
      end

    if post_to_fb && fb_page_id && fb_page_token
      fb_res = post_to_facebook(fb_page_id, fb_page_token, image_url, caption)
      post.update(fb_post_id: fb_res[:id]) if fb_res[:id]
      results << fb_res[:message]
    end

    end

    render json: {
      success: true,
      message: selected_date == Date.today ? results.join(" | ") : "Post scheduled for #{selected_date}"
    }, status: :ok
  rescue => e
    Rails.logger.error("Post creation failed: #{e.message}")
    render json: { error: "Something went wrong. #{e.message}" }, status: :unprocessable_entity
  end

  def destroy
    post = Current.session.user.posts.find(params[:id])
    user = Current.session.user

    if post.fb_post_id.present?
      fb_delete = delete_facebook_post(post.fb_post_id, user.fb_page_token) #  use page token
      Rails.logger.info("Facebook post delete result: #{fb_delete}")
    end

    if post.ig_post_id.present?
      ig_delete = delete_instagram_post(post.ig_post_id, user.fb_token) # IG still uses user token
      Rails.logger.info("Instagram post delete result: #{ig_delete}")
    end

    post.destroy
    #  binding.pry
    redirect_to post_path, notice: "Post deleted successfully."
  end



  private
    def delete_uploaded_file
      return unless @uploaded_file_path.present? && File.exist?(@uploaded_file_path)

      File.delete(@uploaded_file_path)
      Rails.logger.info "Deleted uploaded file: #{@uploaded_file_path}"
    rescue => e
      Rails.logger.error "Failed to delete uploaded file: #{e.message}"
    end

    def upload_image_and_get_url(file)
      require 'mini_magick'

      sanitized_name = file.original_filename.gsub(/[^\w.\-]/, "_")
      filename = "#{SecureRandom.uuid}_#{sanitized_name}"

      upload_dir = Rails.root.join("public", "uploads")
      FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)
      filepath = upload_dir.join(filename)

      image = MiniMagick::Image.read(file)

      # Resize to fit within Instagram’s accepted dimensions, without cropping or padding
      max_width  = 1080
      max_height = 1350

      if image.width > max_width || image.height > max_height
        image.resize "#{max_width}x#{max_height}>"
      end

      image.write(filepath)

      base_url = ENV.fetch("APP_HOST", "https://your-app.com")
      "#{base_url}/uploads/#{filename}"
    end



    def post_to_instagram(ig_user_id, token, image_url, caption)
      Rails.logger.debug("▶ IG Media Create | image_url: #{image_url}, caption: #{caption}")

      uri = URI("https://graph.facebook.com/v18.0/#{ig_user_id}/media")
      res = Net::HTTP.post_form(uri, {
        image_url: image_url,
        caption: caption,
        access_token: token
      })
      res_data = JSON.parse(res.body)
      Rails.logger.debug("📸 IG Media Create Response: #{res_data.inspect}")

      if res_data["error"]
        return { error: true, message: "Media create error: #{res_data["error"]["message"]}" }
      end

      creation_id = res_data["id"]
      publish_uri = URI("https://graph.facebook.com/v18.0/#{ig_user_id}/media_publish")
      publish_res = Net::HTTP.post_form(publish_uri, {
        creation_id: creation_id,
        access_token: token
      })
      publish_data = JSON.parse(publish_res.body)
      Rails.logger.debug("📤 IG Media Publish Response: #{publish_data.inspect}")

      if publish_data["error"]
        { error: true, message: "Publish error: #{publish_data["error"]["message"]}" }
      else
        { error: false, message: "Instagram post published! ID: #{publish_data["id"]}", id: publish_data["id"] }
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
      Rails.logger.debug("[Facebook Response] #{res_data.inspect}") # 👈 Log the full response

      if res_data["error"]
        { error: true, message: res_data["error"]["message"] }
      else
        {
          error: false,
          message: "Facebook post published! ID: #{res_data["post_id"] || res_data["id"]}",
          id: res_data["post_id"] || res_data["id"]
        }
      end

    end

    def delete_facebook_post(post_id, token)
      uri = URI("https://graph.facebook.com/v18.0/#{post_id}?access_token=#{token}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Delete.new(uri.request_uri)
      response = http.request(request)
      JSON.parse(response.body)
    end

    def delete_instagram_post(post_id, token)
      uri = URI("https://graph.facebook.com/v18.0/#{post_id}?access_token=#{token}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Delete.new(uri.request_uri)
      response = http.request(request)
      JSON.parse(response.body)
    end

end

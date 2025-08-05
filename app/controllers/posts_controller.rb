class PostsController < ApplicationController
  after_action :delete_uploaded_file, only: [:create]

  def create
    uploaded_file  = params[:image_file]
    image_url      = params[:image_url]
    caption        = params[:caption]
    post_to_ig     = params[:post_to_ig] == "1"
    post_to_fb     = params[:post_to_fb] == "1"
    schedule_to_post     = params[:schedule_to_post] == "1"
    selected_date = schedule_to_post ? Time.parse(params[:date]) : Time.current
    user           = Current.session.user

    if uploaded_file.present?
      image_url = upload_image_and_get_url(uploaded_file)
      uploaded_file.rewind if uploaded_file.respond_to?(:rewind)
    end

    if image_url.blank? || (!post_to_ig && !post_to_fb)
      render json: { error: "Please select a platform and provide an image." }, status: :unprocessable_entity
      return
    end

    @post = user.posts.create!(
      caption: caption,
      ig: post_to_ig ? 1 : 0,
      fb: post_to_fb ? 1 : 0,
      scheduled_at: selected_date,
      status: schedule_to_post ? 1 : 2
    )

    if uploaded_file.present? && uploaded_file.respond_to?(:tempfile)
      @post.photo.attach(
        io: uploaded_file.tempfile,
        filename: uploaded_file.original_filename,
        content_type: uploaded_file.content_type
      )
    end

    results = []
    if !schedule_to_post
      fb_service = FacebookService.new(user)

      if post_to_ig
        ig_res = fb_service.post_to_instagram(image_url, caption)
        @post.update(ig_post_id: ig_res["id"]) if ig_res["id"]
        results << "Instagram posted!" unless ig_res["error"]
      end

      if post_to_fb
        fb_res = fb_service.post_to_facebook(image_url, caption)
        @post.update(fb_post_id: fb_res["post_id"] || fb_res["id"]) if fb_res["post_id"] || fb_res["id"]
        results << "Facebook posted!" unless fb_res["error"]
      end
    end

    render json: {
      success: true,
      message: schedule_to_post ? results.join(" | ") : "Post scheduled for #{selected_date}"
    }, status: :ok
  rescue => e
    Rails.logger.error("Post creation failed: #{e.message}")
    render json: { error: "Something went wrong. #{e.message}" }, status: :unprocessable_entity
  end

  def destroy
    post = Current.session.user.posts.find(params[:id])
    user = Current.session.user
    fb_service = FacebookService.new(user)

    if post.fb_post_id.present?
      fb_service.delete_facebook_post(post.fb_post_id)
      if post.fb == 1 && post.ig == 0
        post.destroy
        redirect_to post_path, notice: "Post deleted successfully."
        return
      end
      post.update(fb_post_id: nil, fb: 0)
    end

    if post.ig_post_id.present?
      fb_service.delete_instagram_post(post.ig_post_id)
      post.update(ig_post_id: nil, ig: 0)
    end

    redirect_to post_path, notice: "Post deleted successfully."
  end

  def create_linkedin_post
    user = Current.session.user
    uploaded_file = params[:image_file]
    caption = params[:caption] || "Posted via API"
    schedule_to_post = params[:schedule_to_post] == "1"
    selected_time = schedule_to_post ? Time.parse(params[:date]) : Time.current

    unless uploaded_file
      render json: { error: "No image file uploaded" }, status: :unprocessable_entity and return
    end

    if schedule_to_post
      # Schedule post for later
      @post = user.posts.create!(
        caption: caption,
        scheduled_at: selected_time,
        linkedin: 1,
        status: 1,  # status 1 = scheduled
      )

      @post.photo.attach(uploaded_file)

      render json: { message: "Post scheduled for #{selected_time}" }
    else
      # Post immediately
      service = LinkedInService.new(user)
      response = service.create_post(image_file: uploaded_file, caption: caption)

      if response["id"].present?
        linkedin_post_urn = response["id"]
        @post = user.posts.create!(
          caption: caption,
          scheduled_at: Time.current,
          linkedin: 1,
          status: 2,  # status 2 = posted
          linkedin_post_urn: linkedin_post_urn
        )
        @post.photo.attach(uploaded_file)

        render json: { message: "Image post created!", response: response }
      else
        render json: { error: "Failed to post with image", response: response }, status: :unprocessable_entity
      end
    end
  end

  def delete_linkedin_post
    post = Current.session.user.posts.find(params[:id])
    service = LinkedInService.new(Current.session.user)
    response = service.delete_post(post.linkedin_post_urn)

    if response.success?
      post.destroy
      # render json: { message: "LinkedIn post deleted." }
      redirect_to post_path, notice: "Post deleted successfully."
    else
      render json: { error: "Failed to delete LinkedIn post", response: response.parsed_response }, status: :unprocessable_entity
    end
  end

def scheduled_update
  @post = Current.session.user.posts.find(params[:id])

  if @post.update(post_params)
    # Attach photo if provided (from top-level params)
    if params[:photo].present?
      @post.photo.purge if @post.photo.attached?
      @post.photo.attach(params[:photo])
    end

    redirect_to post_path(@post), notice: "Post updated successfully!"
  else
    redirect_to post_path(@post), alert: "Failed to update post."
  end
end

private

def post_params
  params.require(:post).permit(:caption, :scheduled_at, :fb, :ig, :linkedin)
end

  def delete_uploaded_file
    return unless @uploaded_file_path.present? && File.exist?(@uploaded_file_path)

    File.delete(@uploaded_file_path)
    Rails.logger.info "Deleted uploaded file: #{@uploaded_file_path}"
  rescue => e
    Rails.logger.error "Failed to delete uploaded file: #{e.message}"
  end

  def upload_image_and_get_url(file)
    require "mini_magick"

    sanitized_name = file.original_filename.gsub(/[^\w.\-]/, "_")
    filename = "#{SecureRandom.uuid}_#{sanitized_name}"
    upload_dir = Rails.root.join("public", "uploads")
    FileUtils.mkdir_p(upload_dir)
    filepath = upload_dir.join(filename)

    image = MiniMagick::Image.read(file)
    aspect_ratio = image.width.to_f / image.height

    if aspect_ratio < 0.8
      new_height = (image.width / 0.8).round
      offset = ((image.height - new_height) / 2).round
      image.crop("#{image.width}x#{new_height}+0+#{offset}")
    elsif aspect_ratio > 1.91
      new_width = (image.height * 1.91).round
      offset = ((image.width - new_width) / 2).round
      image.crop("#{new_width}x#{image.height}+#{offset}+0")
    end

    image.resize "1080x1350>"
    image.write(filepath)

    base_url = ENV.fetch("APP_HOST", "https://your-app.com")
    "#{base_url}/uploads/#{filename}"
  end
end

class PostsController < ApplicationController
  after_action :delete_uploaded_file, only: [:create]
  require 'oauth'

  ALLOWED_CONTENT_TYPES = %w[image/jpeg image/png image/gif video/mp4 video/quicktime]

  def create
    user             = Current.session.user
    uploaded_files   = Array(params[:image_file])
    image_urls       = Array(params[:image_urls])
    caption          = params[:caption]
    post_to_ig       = params[:post_to_ig] == "1"
    post_to_fb       = params[:post_to_fb] == "1"
    schedule_post    = params[:schedule_to_post] == "1"
    scheduled_date   = schedule_post ? Time.parse(params[:date]) : Time.current

    uploaded_files.each do |file|
      next unless file.present?
      image_urls << MediaUploaderService.new(file).upload_and_get_url
    end

    unless image_urls.any? && (post_to_ig || post_to_fb)
      return render_error("Select a platform and upload at least one image.")
    end

    if post_to_ig && image_urls.size > 1 && contains_video?(image_urls)
      return render_error("Instagram does not support videos in carousel posts.")
    end

    @post = user.posts.create!(
      caption: caption,
      ig: post_to_ig ? 1 : 0,
      fb: post_to_fb ? 1 : 0,
      scheduled_at: scheduled_date,
      status: schedule_post ? 1 : 2
    )

    attach_photos(@post, uploaded_files)

    results = schedule_post ? [] : publish_to_platforms(user, post_to_ig, post_to_fb, image_urls, caption)

    flash[:success] = t(schedule_post ? "alerts.post_scheduled_created" : "alerts.post_created")

    render json: {
      success: true,
      message: schedule_post ? "Post scheduled for #{scheduled_date}" : results.join(" | ")
    }
  rescue => e
    log_and_render_error("Post creation failed: #{e.message}")
  end

  def destroy
    post = Current.session.user.posts.find(params[:id])
    service = FacebookService.new(Current.session.user)

    service.delete_platform_posts(post)
    post.fb.zero? && post.ig.zero? ? post.destroy : post.update(fb: 0, ig: 0, fb_post_id: nil, ig_post_id: nil)

    redirect_to post_path, flash: { success: t("alerts.post_deleted") }
  end

  def create_linkedin_post
    user = Current.session.user
    files = Array.wrap(params[:image_file])
    caption = params[:caption].presence || "Posted via API"
    schedule = params[:schedule_to_post] == "1"
    time = schedule ? Time.parse(params[:date]) : Time.current

    return render_error("No image files uploaded") if files.blank?

    if schedule
      post = user.posts.create!(caption: caption, scheduled_at: time, linkedin: 1, status: 1)
      attach_photos(post, files)
      render json: { message: "Post scheduled for #{time}" }
    else
      response = LinkedInService.new(user).create_post(image_files: files, caption: caption)
      if response["id"].present?
        post = user.posts.create!(
          caption: caption,
          linkedin: 1,
          status: 2,
          scheduled_at: Time.current,
          linkedin_post_urn: response["id"]
        )
        attach_photos(post, files)
        render json: { message: "Post created!", response: response }
      else
        render_error("Failed to post", response)
      end
    end
  end

  def delete_linkedin_post
    post = Current.session.user.posts.find(params[:id])
    service = LinkedInService.new(Current.session.user)
    response = service.delete_post(post.linkedin_post_urn)

    if response.success?
      post.destroy
      redirect_to post_path, flash: { success: t("alerts.post_deleted") }
    else
      render_error("Failed to delete LinkedIn post", response.parsed_response)
    end
  end

  def create_twitter_post
    user = Current.session.user
    profile = user.twitter_profile
    return render_error("Twitter profile not linked.", status: :unauthorized) unless profile

    response = TwitterService.new(profile).post_tweet(params[:caption])
    if response.success?
      user.posts.create!(caption: params[:caption], twitter: 1, status: 2, scheduled_at: Time.current)
     flash[:success] = t("alerts.tweet_created")
      render json: { success: true, tweet_url: response.url }
    else
      render_error(response.error)
    end
  end

  def scheduled_update
    post = Current.session.user.posts.find(params[:id])
    post_data = post_params

    post_data[:scheduled_at] = Time.parse(post_data[:scheduled_at]) rescue nil if post_data[:scheduled_at]

    if post.update(post_data)
      attach_single_photo(post, params[:photo]) if params[:photo].present?
      redirect_to post_path(post), notice: "Post updated successfully!"
    else
      redirect_to post_path(post), alert: "Failed to update post."
    end
  end

  def scheduled_posts_delete
    post = Current.session.user.posts.find(params[:id])
    post.destroy
    redirect_to post_path, flash: { success: t("alerts.post_scheduled_deleted") }
  end

  private

  def post_params
    params.require(:post).permit(:caption, :scheduled_at, :fb, :ig, :linkedin)
  end

  def attach_photos(post, files)
    files.each do |file|
      next unless file.present? && file.respond_to?(:tempfile)
      next unless ALLOWED_CONTENT_TYPES.include?(file.content_type)

      file.tempfile.rewind
      post.photos.attach(
        io: file.tempfile,
        filename: file.original_filename,
        content_type: file.content_type
      )
    end
  end

  def attach_single_photo(post, file)
    post.photo.purge if post.photo.attached?
    post.photo.attach(file)
  end

  def render_error(message, data = {}, status: :unprocessable_entity)
    render json: { error: message, **data }, status: status
  end

  def log_and_render_error(message)
    Rails.logger.error(message)
    render_error(message)
  end

  def contains_video?(urls)
    urls.any? { |url| url.match?(/\.(mp4|mov)$/i) }
  end

  def publish_to_platforms(user, to_ig, to_fb, urls, caption)
    fb_service = FacebookService.new(user)
    results = []

    if to_ig
      res = fb_service.post_to_instagram(urls, caption)
      @post.update(ig_post_id: res["id"]) if res["id"]
      results << "Instagram posted!" unless res["error"]
    end

    if to_fb
      res = fb_service.post_to_facebook(urls, caption)
      @post.update(fb_post_id: res["post_id"] || res["id"]) if res["post_id"] || res["id"]
      results << "Facebook posted!" unless res["error"]
    end

    results
  end

  def delete_uploaded_file
    return unless @uploaded_file_path && File.exist?(@uploaded_file_path)
    File.delete(@uploaded_file_path)
  rescue => e
    Rails.logger.error "Failed to delete uploaded file: #{e.message}"
  end
end

class PostSchedulerJob < ApplicationJob
  queue_as :default


  def perform

      today = Time.zone.today
      Post.where(status: 1, scheduled_at: ..Time.current).includes(:user, photo_attachment: :blob).find_each do |post|
      user = post.user
      next unless user

      results = []

      # IG Posting
      if post.ig == 1 && user.ig_user_id.present? && user.fb_token.present?
        begin
          Rails.logger.info("[PostSchedulerJob] Attempting Instagram post for Post##{post.id}")
          image_url = generate_processed_image_url(post)

            Rails.logger.info("[PostSchedulerJob] IG image_url: #{image_url}")

            # binding.pry
          rescue => e
          res = post_to_instagram(user.ig_user_id, user.fb_token, image_url, post.caption)

                    res = post_to_instagram(user.ig_user_id, user.fb_token, image_url, post.caption)

                    post.update(ig_post_id: res[:id]) if res[:id] #  Store Instagram post ID
                    results << "Instagram: #{res[:message]}"
            Rails.logger.error("[PostSchedulerJob] IG post failed for Post##{post.id}:\n" \
                              "User ID: #{user.ig_user_id}\n" \
                              "Token: #{user.fb_token[0..10]}...\n" \
                              "Image URL: #{image_url}\n" \
                              "#{e.class} - #{e.message}\n#{e.backtrace.join("\n")}")
            results << "Instagram failed"
        end
      end

      if post.fb == 1 && user.fb_page_id.present? && user.fb_page_token.present?
        begin
          Rails.logger.info("[PostSchedulerJob] Attempting Facebook post for Post##{post.id}")
          res = post_to_facebook(user.fb_page_id, user.fb_page_token, post.photo_url, post.caption)
          post.update(fb_post_id: res[:id]) if res[:id] #  Store Facebook post ID
          results << "Facebook: #{res[:message]}"
        rescue => e
          Rails.logger.error("[PostSchedulerJob] FB post failed for Post##{post.id}: #{e.message}")
          results << "Facebook failed"
        end
      end

      if post.linkedin == 1 && user.linkedin_token.present? && user.linkedin_id.present?
        begin
          Rails.logger.info("[PostSchedulerJob] Attempting LinkedIn post for Post##{post.id}")
          photo_file = StringIO.new(post.photo.blob.download)
          photo_file.set_encoding('BINARY')
          photo_file.define_singleton_method(:content_type) { post.photo.blob.content_type }

          linkedin_service = LinkedInService.new(user)
          response = linkedin_service.create_post(image_file: photo_file, caption: post.caption)

          linkedin_post_urn = response["id"]
          post.update(linkedin_post_urn: linkedin_post_urn) if linkedin_post_urn.present?
          results << "LinkedIn: Post published!"
        rescue => e
          Rails.logger.error("[PostSchedulerJob] LinkedIn post failed for Post##{post.id}: #{e.message}")
          results << "LinkedIn failed"
        end
      end

      # binding.pry

      # Update status if posted
      if results.any?
        post.update(status: 2)
        Rails.logger.info("[PostSchedulerJob] Post##{post.id} marked as posted. Results: #{results.join(' | ')}")
      else
        Rails.logger.warn("[PostSchedulerJob] Post##{post.id} skipped: no valid platform/credentials")
      end
    end
  end

  private

  def post_to_instagram(ig_user_id, fb_token, image_url, caption)
    creation_uri = URI("https://graph.facebook.com/v18.0/#{ig_user_id}/media")
    creation_params = {
      image_url: image_url,
      caption: caption,
      access_token: fb_token
    }

    creation_res = Net::HTTP.post_form(creation_uri, creation_params)
    Rails.logger.info("[IG API] Media creation response: #{creation_res.body}")
    creation_data = JSON.parse(creation_res.body)

    raise "IG media creation failed: #{creation_data}" unless creation_data["id"]

    publish_uri = URI("https://graph.facebook.com/v18.0/#{ig_user_id}/media_publish")
    publish_res = Net::HTTP.post_form(publish_uri, {
      creation_id: creation_data["id"],
      access_token: fb_token
    })
    Rails.logger.info("[IG API] Media publish response: #{publish_res.body}")
    publish_data = JSON.parse(publish_res.body)

    raise "IG publish failed: #{publish_data}" unless publish_data["id"]

    {
      error: false,
      message: "Instagram post published! ID: #{publish_data["id"]}",
      id: publish_data["id"]
    }
  end


  def post_to_facebook(page_id, page_token, image_url, caption)
    fb_uri = URI("https://graph.facebook.com/v18.0/#{page_id}/photos")
    fb_params = {
      url: image_url,
      caption: caption,
      access_token: page_token
    }

    fb_res = Net::HTTP.post_form(fb_uri, fb_params)
    fb_data = JSON.parse(fb_res.body)

    raise "FB post failed: #{fb_data}" unless fb_data["id"]

    {
      error: false,
      message: "Facebook post published! ID: #{fb_data["post_id"] || fb_data["id"]}",
      id: fb_data["post_id"] || fb_data["id"]
    }

  end

  require 'mini_magick'
  require 'fileutils'
  require 'securerandom'

  def generate_processed_image_url(post)
    photo = post.photo
    return nil unless photo.attached?

    file = photo.blob.download
    image = MiniMagick::Image.read(file)


    width = image.width
    height = image.height
    aspect_ratio = width.to_f / height

    min_ratio = 0.8   # 4:5
    max_ratio = 1.91  # 1.91:1

    if aspect_ratio < min_ratio
      new_height = (width / min_ratio).round
      offset = ((height - new_height) / 2).round
      image.crop("#{width}x#{new_height}+0+#{offset}")
    elsif aspect_ratio > max_ratio
      new_width = (height * max_ratio).round
      offset = ((width - new_width) / 2).round
      image.crop("#{new_width}x#{height}+#{offset}+0")
    end

    # Resize to Instagram-compatible size
    image.resize "1080x1350>"
    image.format "jpg"

    safe_filename = "#{SecureRandom.uuid}_#{photo.filename.to_s.parameterize}.jpg"

    upload_dir = Rails.root.join("public", "uploads")
    FileUtils.mkdir_p(upload_dir)
    filepath = upload_dir.join(safe_filename)
    image.write(filepath)

    base_url = ENV.fetch("APP_HOST", "https://bc91ba221f41.ngrok-free.app")
    "#{base_url}/uploads/#{safe_filename}"
  end
end

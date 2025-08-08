class PostSchedulerJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post && post.status == 1 && post.scheduled_at.present? && post.scheduled_at <= Time.current

    user = post.user
    caption = post.caption

    begin
      # Prepare safe, reusable file objects for LinkedIn (image/video)
      media_files = post.photos.map do |photo|
        {
          io: StringIO.new(photo.blob.download),
          content_type: photo.blob.content_type,
          filename: photo.blob.filename.to_s
        }
      end

      # Prepare direct URLs for Facebook/Instagram (must be public)
      media_urls = post.photos.map do |photo|
        Rails.application.routes.url_helpers.rails_blob_url(photo, only_path: false)
      end

      # LinkedIn
      if post.linkedin?
        linkedin_service = LinkedInService.new(user)
        response = linkedin_service.create_post(image_files: media_files, caption: caption)

        if response["id"].present?
          post.update!(linkedin_post_urn: response["id"])
        else
          raise "LinkedIn post failed: #{response.inspect}"
        end
      end

      # Facebook + Instagram
      if post.fb? || post.ig?
        fb_service = FacebookService.new(user)

        if post.fb?
          fb_response = fb_service.post_to_facebook(media_urls, caption)
          if fb_response["error"].present?
            raise "Facebook post failed: #{fb_response["error"]["message"]}"
          end
          post.update!(fb_post_id: fb_response["id"] || fb_response["post_id"])
        end

        if post.ig?
          ig_response = fb_service.post_to_instagram(media_urls, caption)
          if ig_response["error"].present?
            raise "Instagram post failed: #{ig_response["error"]["message"]}"
          end
          post.update!(ig_post_id: ig_response["id"])
        end
      end

      post.update!(status: 2, posted_at: Time.current) # Mark as posted
    rescue => e
      Rails.logger.error("[PostSchedulerJob] Failed: #{e.message}")
      post.update!(status: 3, error_message: e.message) # Mark as failed
    end
  end
end

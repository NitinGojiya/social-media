class PostSchedulerJob < ApplicationJob
  queue_as :default

  def perform
    today = Time.zone.today
    Post.where(status: 1, scheduled_at: Time.zone.today.all_day).includes(:user, photo_attachment: :blob).find_each do |post|
      user = post.user
      next unless user

      results = []

      # IG Posting
      if post.ig == 1 && user.ig_user_id.present? && user.fb_token.present?
        begin
          Rails.logger.info("[PostSchedulerJob] Attempting Instagram post for Post##{post.id}")
          res = post_to_instagram(user.ig_user_id, user.fb_token, post.photo_url, post.caption)
          post.update(ig_post_id: res[:id]) if res[:id] # ✅ Store Instagram post ID
          results << "Instagram: #{res[:message]}"
        rescue => e
          Rails.logger.error("[PostSchedulerJob] IG post failed for Post##{post.id}: #{e.message}")
          results << "Instagram failed"
        end
      end

      if post.fb == 1 && user.fb_page_id.present? && user.fb_page_token.present?
        begin
          Rails.logger.info("[PostSchedulerJob] Attempting Facebook post for Post##{post.id}")
          res = post_to_facebook(user.fb_page_id, user.fb_page_token, post.photo_url, post.caption)
          post.update(fb_post_id: res[:id]) if res[:id] # ✅ Store Facebook post ID
          results << "Facebook: #{res[:message]}"
        rescue => e
          Rails.logger.error("[PostSchedulerJob] FB post failed for Post##{post.id}: #{e.message}")
          results << "Facebook failed"
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
    creation_data = JSON.parse(creation_res.body)

    raise "IG media creation failed: #{creation_data}" unless creation_data["id"]

    publish_uri = URI("https://graph.facebook.com/v18.0/#{ig_user_id}/media_publish")
    publish_res = Net::HTTP.post_form(publish_uri, {
      creation_id: creation_data["id"],
      access_token: fb_token
    })
    publish_data = JSON.parse(publish_res.body)

    raise "IG publish failed: #{publish_data}" unless publish_data["id"]
    { error: false, message: "Instagram post published! ID: #{publish_data["id"]}", id: publish_data["id"] }

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
end

class LinkedInScheduledPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)

    return unless post && post.status == 1 && post.scheduled_at <= Time.current

    user = post.user
    service = LinkedInService.new(user)
    image_file = post.photo.blob.download

    response = service.create_post(image_file: StringIO.new(image_file), caption: post.caption)

    if response.success?
      post.update!(
        status: 2,
        linkedin_post_urn: response.parsed_response["id"]
      )
    else
      post.update!(status: 3) # Optional: status 3 = failed
      Rails.logger.error("Failed to publish scheduled LinkedIn post ID #{post.id}: #{response.parsed_response}")
    end
  end
end

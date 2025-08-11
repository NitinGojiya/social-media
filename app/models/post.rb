class Post < ApplicationRecord
  include Rails.application.routes.url_helpers
  include ActionDispatch::Routing::UrlFor

  belongs_to :user
  has_many_attached :photos

  # Status:
  # 1 = scheduled, 2 = posted

  scope :scheduled, -> { where(status: 1) }
  scope :posted,    -> { where(status: 2) }

  scope :for_today,           -> { where(scheduled_at: Time.zone.today.all_day) }
  scope :future,              -> { where("scheduled_at > ?", Time.zone.now) }
  scope :scheduled_for_today, -> { where(status: 1, scheduled_at: Date.today) }

  before_destroy :purge_photos

  MAX_IMAGES = 9
  MAX_VIDEOS = 1
  MAX_FILE_SIZE_MB = 150
  ALLOWED_IMAGE_TYPES = %w[image/jpeg image/png image/gif]
  ALLOWED_VIDEO_TYPES = %w[video/mp4 video/quicktime]

  before_validation :validate_media_count_and_type
  before_validation :validate_file_size
  validate :scheduled_at_must_be_in_future, if: -> { status == 1 && scheduled_at.present? }

  def photo_urls
    return [] unless photos.attached?
    photos.map do |img|
      rails_blob_url(img, host: Rails.application.routes.default_url_options[:host])
    end
  end

  private
  def scheduled_at_must_be_in_future
    if scheduled_at < Time.zone.now
      errors.add(:scheduled_at, "must be in the future")
    end
  end

  def purge_photos
    photos.purge_later
  end

  # ----------------
  # Validation rules
  # ----------------
  def validate_media_count_and_type
    return unless photos.attached?

    image_count = photos.count { |p| ALLOWED_IMAGE_TYPES.include?(p.content_type) }
    video_count = photos.count { |p| ALLOWED_VIDEO_TYPES.include?(p.content_type) }

    if video_count > MAX_VIDEOS
      errors.add(:photos, "only #{MAX_VIDEOS} video allowed per post")
    end

    if video_count > 0 && image_count > 0
      errors.add(:photos, "cannot mix images and videos in the same post")
    end

    if image_count > MAX_IMAGES
      errors.add(:photos, "can upload up to #{MAX_IMAGES} images only")
    end

    if photos.any? { |p| !ALLOWED_IMAGE_TYPES.include?(p.content_type) && !ALLOWED_VIDEO_TYPES.include?(p.content_type) }
      errors.add(:photos, "contains an unsupported file type")
    end
  end

  def validate_file_size
    return unless photos.attached?

    photos.each do |file|
      if file.blob.byte_size > MAX_FILE_SIZE_MB.megabytes
        errors.add(:photos, "#{file.filename} exceeds #{MAX_FILE_SIZE_MB} MB size limit")
      end
    end
  end
end

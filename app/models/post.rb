class Post < ApplicationRecord
   include Rails.application.routes.url_helpers
  include ActionDispatch::Routing::UrlFor # ✅ REQUIRED for rails_blob_url

  belongs_to :user
  has_one_attached :photo

  scope :scheduled, -> { where(status: 1) }
  scope :posted, -> { where(status: 2) }

  scope :for_today, -> { where(scheduled_at: Time.zone.today.all_day) }
  scope :future,    -> { where("scheduled_at > ?", Time.zone.now) }

  scope :scheduled_for_today, -> { where(status: 1, scheduled_at: Date.today) }
  before_destroy :purge_photo


def photo_url
  return nil unless photo.attached?

  # Use default_url_options[:host] instead of config.default_url_host
  rails_blob_url(photo, host: Rails.application.routes.default_url_options[:host])
end

  private

  def purge_photo
    photo.purge_later
  end
end

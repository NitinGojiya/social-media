class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :photo

  scope :scheduled, -> { where(status: 1) }
  scope :posted, -> { where(status: 2) }

  scope :for_today, -> { where(scheduled_at: Time.zone.today.all_day) }
  scope :future,    -> { where("scheduled_at > ?", Time.zone.now) }

  scope :scheduled_for_today, -> { where(status: 1, scheduled_at: Date.today) }
  before_destroy :purge_photo

  include Rails.application.routes.url_helpers

  def photo_url
    return nil unless photo.attached?
    Rails.application.routes.url_helpers.rails_blob_url(photo, host: Rails.application.config.default_url_host)
  end
  private

  def purge_photo
    photo.purge_later
  end
end

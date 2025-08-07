class Post < ApplicationRecord
  include Rails.application.routes.url_helpers
  include ActionDispatch::Routing::UrlFor

  belongs_to :user
  has_many_attached :photos

  scope :scheduled, -> { where(status: 1) }
  scope :posted,    -> { where(status: 2) }

  scope :for_today,           -> { where(scheduled_at: Time.zone.today.all_day) }
  scope :future,              -> { where("scheduled_at > ?", Time.zone.now) }
  scope :scheduled_for_today, -> { where(status: 1, scheduled_at: Date.today) }

  before_destroy :purge_photos

  def photo_urls
    return [] unless photos.attached?

    photos.map do |img|
      rails_blob_url(img, host: Rails.application.routes.default_url_options[:host])
    end
  end


  private

  def purge_photos
    photos.purge_later
  end
end

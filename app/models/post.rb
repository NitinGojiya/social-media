class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :photo

  scope :scheduled, -> { where(status: 1) }
  scope :posted, -> { where(status: 2) }

  scope :for_today, -> { where(scheduled_at: Time.zone.today.all_day) }
  scope :future,    -> { where("scheduled_at > ?", Time.zone.now) }

  before_destroy :purge_photo

  private

  def purge_photo
    photo.purge_later
  end
end

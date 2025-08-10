class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :linkedin_profiles, dependent: :destroy
  has_one :twitter_profile, dependent: :destroy

  has_one_attached :profile_photo, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, uniqueness: { case_sensitive: false }

  # Only require password when creating a new user
  validates :password, presence: true, on: :create
  validates :password, format: {
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).{8,}\z/,
    message: "must be at least 8 characters long and include one uppercase letter, one lowercase letter, and one symbol"
  }, allow_nil: true # allow_nil lets profile updates pass without new password
end

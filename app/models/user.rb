class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_many :linkedin_profiles, dependent: :destroy
  has_one :twitter_profile, dependent: :destroy
  validates :email_address, uniqueness: { case_sensitive: false }

  validates :password, presence: true
  validates :password, format: {
    with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*[\W_]).{8,}\z/,
    message: "must be at least 8 characters long and include one uppercase letter, one lowercase letter, and one symbol"
  }
end

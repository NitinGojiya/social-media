class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :posts
  normalizes :email_address, with: ->(e) { e.strip.downcase }

  has_many :linkedin_profiles, dependent: :destroy
end

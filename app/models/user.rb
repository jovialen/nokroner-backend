class User < ApplicationRecord
  # User authentication
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  has_secure_password
  has_many :sessions, dependent: :destroy

  # User profile
  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile
  validates :profile, presence: true
end

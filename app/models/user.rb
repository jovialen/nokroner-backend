class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_many :all_groups, class_name: "Group", foreign_key: "created_by_id"
  belongs_to :group, optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end

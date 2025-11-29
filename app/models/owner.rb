class Owner < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :creator, class_name: "User", foreign_key: "creator_id"

  has_many :accounts, dependent: :destroy

  validates :creator, presence: true
  validates :user, comparison: { equal_to: :creator }, allow_nil: true

  scope :created_by_user, ->(user) { where(creator_id: user.id) }
end

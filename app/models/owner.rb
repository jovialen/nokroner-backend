class Owner < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  belongs_to :user, optional: true

  has_many :accounts, dependent: :destroy

  validates :user, comparison: { equal_to: :creator }, allow_nil: true

  scope :created_by_user, ->() { where(creator_id: Current.user) }
end

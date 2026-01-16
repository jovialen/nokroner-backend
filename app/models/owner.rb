class Owner < ApplicationRecord
  belongs_to :created_by, class_name: "User", foreign_key: :created_by_id
  has_one :user, foreign_key: :owner_id

  scope :created_by_user, ->() { where(created_by: Current.user) }

end

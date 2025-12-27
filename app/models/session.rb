class Session < ApplicationRecord
  belongs_to :user
  before_create :generate_token

  scope :created_by_user, ->() { where(user: Current.user) }

  def regenerate_token!
    generate_token
    save
  end

  def generate_token
    self.token = SecureRandom.hex(32)
  end
end

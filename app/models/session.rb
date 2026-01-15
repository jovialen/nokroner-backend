class Session < ApplicationRecord
  belongs_to :user
  has_secure_token :auth_token

  def expired?
    expires_at <= Time.current
  end

  def regenerate_auth_token!
    regenerate_auth_token
    update!(expires_at: 30.days.from_now)
  end
end

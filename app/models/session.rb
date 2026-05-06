class Session < ApplicationRecord
  belongs_to :user
  after_create_commit :generate_refresh_token

  def generate_access_token
    JWT.encode(payload(expires_in: 1.hour), ENV["ACCESS_TOKEN_SECRET"], "HS256")
  end

  private

  def generate_refresh_token
    update!(refresh_token: JWT.encode(payload(expires_in: 2.weeks), ENV["REFRESH_TOKEN_SECRET"], "HS256"))
  end

  def payload(expires_in:)
    exp = Time.now + expires_in
    { session: self.id, exp: exp.to_i }
  end
end

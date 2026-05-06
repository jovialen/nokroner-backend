module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_access_token
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_access_token, **options
    end

    def allow_refresh_token_only(**options)
      skip_before_action :require_access_token, **options
      before_action :require_refresh_token, **options
    end
  end

  def create_new_session_for_user!(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip)
  end

  private

  def require_access_token
    @secret = ENV["ACCESS_TOKEN_SECRET"]
    require_authorization
  end

  def require_refresh_token
    @secret = ENV["REFRESH_TOKEN_SECRET"]
    require_authorization
  end

  def require_authorization
    render_unauthorized unless resume_session
  rescue JWT::ExpiredSignature
    render_expired
  end

  def resume_session
    payload = decoded_token
    Current.session = payload && Session.find_by(id: payload["session"])
  end

  def decoded_token
    begin
      token = extract_token
      decoded = token && JWT.decode(token, @secret, true, { algorithm: "HS256" })
      decoded&.first
    rescue JWT::VerificationError
      nil
    end
  end

  def extract_token
    request.headers["Authorization"]&.split(" ")&.last
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def render_expired
    render json: { error: "Token expired" }, status: :unauthorized
  end
end

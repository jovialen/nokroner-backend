module Authentication
  extend ActiveSupport::Concern

  include ActionController::Cookies

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_token
  end

  def find_session_by_token
    token = token_from_headers || token_from_cookie
    Session.find_by(auth_token: token)
  end

  def token_from_headers
    header = request.headers['Authorization']
    return nil unless header

    pattern = /^Bearer /
    header.gsub(pattern, '') if header.match(pattern)
  end

  def token_from_cookie
    cookies.encrypted[:auth_token]
  end

  def request_authentication
    if browser_request?
      session[:after_authentication_url] = request.url
      redirect_to "/register/new"
    else
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end

  def browser_request?
    request.headers['Accept']&.include?('text/html') ||
      request.user_agent&.match?(/Mozilla|Chrome|Safari|Firefox/)
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.encrypted[:auth_token] = {
        value: session.auth_token,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        expires: session.expires_at,
      }
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:auth_token)
  end
end

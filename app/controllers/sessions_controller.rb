class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  allow_refresh_token_only only: %i[ update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { render json: { error: "Too many requests. Try again later." }, status: :too_many_requests }

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      session = create_new_session_for_user!(user)
      render json: { refresh_token: session.refresh_token, access_token: session.generate_access_token }, status: :created
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  def update
    render json: { access_token: Current.session.generate_access_token }, status: :created
  end

  def destroy
    Current.session.destroy
  end
end

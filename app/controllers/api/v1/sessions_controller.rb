class Api::V1::SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "Try again later." }

  def create
    if (user = User.authenticate_by(params.permit(:email_address, :password)))
      start_new_session_for user

      render json: Current.session unless browser_request?
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end

  def destroy
    terminate_session

    if browser_request?
      redirect_to home_path, status: :see_other
    else
      head(:ok)
    end
  end
end

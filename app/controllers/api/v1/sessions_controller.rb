class Api::V1::SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to login_path, alert: "Try again later." }

  # @summary Log in to user
  # @auth [bearer, api_key_cookie]
  # Log in to a user from username and password.
  #
  # @request_body User credentials. [!Hash{ email_address: String, password: String }]
  # @request_body_example Example user. [{ "email_address": "user@example.com", "password": "abc123" }]
  # @response Success(200) [!Session]
  # @response Unauthorized(401) [!Hash{ error: String }]
  def create
    if (user = User.authenticate_by(params.permit(:email_address, :password)))
      start_new_session_for user

      render json: Current.session unless browser_request?
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

  # @summary Log out from user
  # @auth [bearer, api_key_cookie]
  # Log out from the currently logged-in user and delete the relevant session.
  #
  # @response Success(200) []
  def destroy
    terminate_session

    if browser_request?
      redirect_to home_path, status: :see_other
    else
      head(:ok)
    end
  end
end

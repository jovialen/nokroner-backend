class Api::V1::UserController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  before_action :set_user, only: [ :show, :destroy ]

  # @summary Show user information
  # @auth [bearer, api_key_cookie]
  # @response Current user information [!User]
  def show
    render json: {
      email_address: @user.email_address,
      created_at: @user.created_at,
      updated_at: @user.updated_at
    }
  end

  # @summary Register a new user
  # @auth [bearer, api_key_cookie]
  # Create a new user and log into it if successful
  #
  # @request_body Username and password [!Hash{ email_address: String, password: String, password_confirmation: String, profile_attributes: !Hash{ first_name: String, last_name: String, date_of_birth: Date } }]
  # @request_body_example Example user [{ "email_address": "user@example.com", "password": "abc123", "password_confirmation": "abc123", "profile_attributes": { "first_name": "Example", "last_name": "User", date_of_birth: "2000-01-01" } }]
  # @response Created(201) [!Hash{ user: !User, api_token: String }]
  # @response Invalid input(422) [!Hash{ errors: Array<String> }]
  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      render json: { user: @user, api_token: Current.session.auth_token } unless browser_request?
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # @summary Delete your user.
  # @auth [bearer, api_key_cookie]
  # Delete the logged in user.
  #
  # @response Success(200) []
  def destroy
    @user.destroy
    head(:ok)
  end

  private

  def set_user
    @user = Current.user
  end

  def user_params
    params.expect(user: [
      :email_address,
      :password,
      :password_confirmation,
      profile_attributes: [ :first_name, :last_name, :date_of_birth ]
    ])
  end
end

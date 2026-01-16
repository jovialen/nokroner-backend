class Api::V1::UserController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  before_action :set_user, only: [ :show, :destroy ]

  def show
    render json: {
      email_address: @user.email_address,
      created_at: @user.created_at,
      updated_at: @user.updated_at
    }
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      render json: { user: @user, api_token: Current.session.auth_token } unless browser_request?
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

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

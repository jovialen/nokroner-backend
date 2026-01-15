class Api::V1::UserController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  before_action :set_user, only: [ :show, :destroy ]

  include Registration

  def show
    render json: {
      email_address: @user.email_address,
      created_at: @user.created_at,
      updated_at: @user.updated_at,
    }
  end

  def create
    if register_new_user
      render json: { user: @user, api_token: Current.session.auth_token }
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
end

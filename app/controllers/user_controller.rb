class UserController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  before_action :find_user, only: %i[ update destroy ]
  wrap_parameters :user, include: %i[ email_address password password_confirmation ]

  def create
    @user = UserCreationService.call(user_params)
    session = create_new_session_for_user!(@user)
    render json: { refresh_token: session.refresh_token, access_token: session.generate_access_token }, status: :created
  end

  def show
    @user = Current.user
    render json: @user, except: [ :password_digest ]
  end

  def update
    @user = Current.user
    @user.update!(user_params)
  end

  def destroy
    @user.destroy
  end

  private

  def user_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end
end

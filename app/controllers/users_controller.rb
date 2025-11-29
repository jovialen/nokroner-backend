class UsersController < ApplicationController
  # GET /users/me
  def show
    @user = Current.user
    render json: @user
  end
end

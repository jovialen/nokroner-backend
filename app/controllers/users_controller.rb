class UsersController < ApplicationController
  # GET /user
  def show
    @user = Current.user
    render json: @user
  end
end

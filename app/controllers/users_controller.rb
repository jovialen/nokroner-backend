class UsersController < ApplicationController
  def show
    @user = Current.user
    render json: @user
  end
end

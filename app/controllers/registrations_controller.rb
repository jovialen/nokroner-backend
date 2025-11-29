class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  # GET /registration
  def new
  end

  # POST /registration
  def create
    ActiveRecord::Base.transaction do
      @user = User.new(user_params)
      @owner = @user.build_owner(creator: @user, is_user: true)

      unless @user.save && @owner.save
        raise ActiveRecord::Rollback
      end
    end

    if @user.persisted? && @owner.persisted?
      render json: @user, status: :created
    else
      render json: { errors: @user.errors.full_messages + @profile.errors.full_messages }, status: :unprocessable_content
    end
  rescue ActiveRecord::Rollback
    render json: { errors: 'User and Owner could not be saved. Try again later' }, status: :unprocessable_content
  end

  # DELETE /registration
  def destroy
    Current.user.destroy!
  end

  private
    def user_params
      params.expect(user: [ :email_address, :password, :password_confirmation, :first_name, :last_name ])
    end
end

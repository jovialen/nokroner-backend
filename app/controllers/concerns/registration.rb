module Registration
  extend ActiveSupport::Concern

  include Authentication

  private

  def register_new_user
    @user = User.new(user_params)

    if @user.save
      start_new_session_for(@user)
      true
    else
      false
    end
  end

  def user_params
    params.expect(user: [ :email_address, :password, :password_confirmation ])
  end
end

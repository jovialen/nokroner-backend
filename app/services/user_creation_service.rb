class UserCreationService
  def self.call(user_params)
    new(user_params).call
  end

  def initialize(user_params)
    @user_params = user_params
  end

  def call
    user = nil

    ApplicationRecord.transaction do
      user = User.new(@user_params.except(:group_id))
      user.save!

      group = user.all_groups.create!(name: "Me")

      user.update!(group: group)
    end

    user
  end
end

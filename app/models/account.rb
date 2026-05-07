class Account < ApplicationRecord
  belongs_to :owner, class_name: "Group"

  validate :owner_belongs_to_user, if: -> { owner.present? }

  private

  def owner_belongs_to_user
    unless owner.created_by == Current.user
      # Let's not reveal if the group exists or not
      errors.add(:owner, "doesn't exist")
    end
  end
end

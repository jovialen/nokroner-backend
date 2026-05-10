class Transaction < ApplicationRecord
  belongs_to :from, class_name: "Account"
  belongs_to :to, class_name: "Account"

  validate :belongs_to_user

  private

  def belongs_to_user
    unless from.present? && from.owner.created_by == Current.user
      errors.add(:from, "must be a valid account")
    end

    unless to.present? && to.owner.created_by == Current.user
      errors.add(:to, "must be a valid account")
    end
  end
end

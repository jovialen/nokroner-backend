class AccountOwnerValidator < ActiveModel::Validator
  def validate(record)
    unless record.owner.blank?
      if record.owner.creator_id != record.creator_id
        record.errors.add :owner, "must have same creator"
      end
    end
  end
end

class Account < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: "creator_id"
  belongs_to :owner, optional: true

  validates :account_number, presence: true
  validates :balance, comparison: { greater_than_or_equal_to: 0.0 }
  validates :interest, comparison: { greater_than_or_equal_to: 0.0 }

  validates_with AccountOwnerValidator
  
  scope :created_by_user, ->() { where(creator_id: Current.user) }
end

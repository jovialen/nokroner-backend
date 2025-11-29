class TransactionAccountCreatorValidator < ActiveModel::Validator
  def validate(record)
    if record.creator_id != record.to_account.creator_id
      record.errors.add :to_account, "must have same creator"
    end

    if record.creator_id != record.from_account.creator_id
      record.errors.add :from_account, "must have same creator"
    end
  end
end

class Transaction < ApplicationRecord
  belongs_to :creator, class_name: "User", foreign_key: "creator_id"

  has_one :from_account, class_name: "Account", foreign_key: "from_account_id"
  has_one :to_account, class_name: "Account", foreign_key: "to_account_id"

  validates :name, presence: true
  validates :amount, comparison: { greater_than: 0.0 }

  validates_with TransactionAccountCreatorValidator

  scope :created_by_user, ->() { where(creator_id: Current.user) }
end

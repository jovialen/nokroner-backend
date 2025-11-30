class AccountOwnerValidator < ActiveModel::Validator
  def validate(record)
    unless record.owner.blank?
      if record.owner.creator_id != record.creator_id
        record.errors.add :owner, 'must have same creator'
      end
    end
  end
end

class Account < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  belongs_to :owner, optional: true

  has_many :sent_transactions, class_name: 'Transaction', foreign_key: 'from_account_id'
  has_many :received_transactions, class_name: 'Transaction', foreign_key: 'to_account_id'

  validates :account_number, presence: true
  validates :balance, comparison: { greater_than_or_equal_to: 0.0 }
  validates :interest, comparison: { greater_than_or_equal_to: 0.0 }

  validates_with AccountOwnerValidator

  scope :created_by_user, ->() { where(creator_id: Current.user) }

  def withdraw!(amount)
    if amount <= 0
      errors.add :base, 'amount must be greater than zero'
      return false
    end

    if balance < amount
      errors.add :balance, 'insufficient funds'
      return false
    end

    update!(balance: balance - amount)
  end

  def deposit!(amount)
    if amount <= 0
      errors.add :base, 'amount must be greater than zero'
      return false
    end

    update!(balance: balance + amount)
  end
end

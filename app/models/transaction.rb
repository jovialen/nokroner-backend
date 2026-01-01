class TransactionAccountsValidator < ActiveModel::Validator
  def validate(record)
    if record.creator_id != record.to_account.creator_id
      record.errors.add :to_account, 'must have same creator'
    end

    if record.creator_id != record.from_account.creator_id
      record.errors.add :from_account, 'must have same creator'
    end

    if record.from_account.balance < record.amount
      record.errors.add :from_account, 'insufficient balance'
    end
  end
end

class Transaction < ApplicationRecord
  after_create :make_transaction
  before_update :undo_transaction
  after_update :make_transaction
  before_destroy :undo_transaction

  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'

  belongs_to :from_account, class_name: 'Account', foreign_key: 'from_account_id'
  belongs_to :to_account, class_name: 'Account', foreign_key: 'to_account_id'

  validates :name, presence: true
  validates :amount, comparison: { greater_than: 0.0 }

  validates_with TransactionAccountsValidator

  scope :created_by_user, ->() { where(creator_id: Current.user) }

  scope :recent, ->() { where(created_at: 31.days.ago..Time.current) }
  scope :previous, ->() { where(created_at: 62.days.ago..31.days.ago) }
  scope :this_month, ->() { where(created_at: Date.today.all_month) }
  scope :last_month, ->() { where(created_at: Time.current.last_month.all_month) }

  private
    def make_transaction
      ActiveRecord::Base.transaction do
        unless from_account.withdraw!(amount) && to_account.deposit!(amount) then
          raise ActiveRecord::Rollback
        end
      end
    rescue ActiveRecord::Rollback
      errors.add :base, 'Failed to make transaction'
      throw :abort
    end

    def undo_transaction
      ActiveRecord::Base.transaction do
        unless to_account.withdraw!(amount) && from_account.deposit(amount) then
          raise ActiveRecord::Rollback
        end
      end
    rescue ActiveRecord::Rollback
      errors.add :base, 'Failed to undo transaction'
      throw :abort
    end
end

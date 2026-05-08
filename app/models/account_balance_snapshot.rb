class AccountBalanceSnapshot < ApplicationRecord
  belongs_to :account

  scope :at_or_after, ->(date) { AccountBalanceSnapshot.where(date: date..) }
  scope :at, ->(date) { AccountBalanceSnapshot.where(date: date) }
  scope :at_or_before, ->(date) { AccountBalanceSnapshot.where(date: ..date) }
end

class AccountBalanceSnapshot < ApplicationRecord
  belongs_to :account

  scope :at_or_after, ->(date) { where(date: date..) }
  scope :at, ->(date) { where(date: date) }
  scope :at_or_before, ->(date) { where(date: ..date) }
end

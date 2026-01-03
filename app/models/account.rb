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
  validates :interest, comparison: { greater_than_or_equal_to: 1.0 }

  validates_with AccountOwnerValidator

  scope :created_by_user, ->() { where(creator_id: Current.user) }

  def recent_income
    self[:recent_income] || received_transactions.external.recent.sum(:amount)
  end

  def recent_expenses
    self[:recent_expenses] || sent_transactions.external.recent.sum(:amount)
  end

  def previous_income
    self[:previous_income] || received_transactions.external.previous.sum(:amount)
  end

  def previous_expenses
    self[:previous_expenses] || sent_transactions.external.previous.sum(:amount)
  end

  def balance_last_month
    month_income = received_transactions.external.this_month.sum(:amount)
    month_expenses = sent_transactions.external.this_month.sum(:amount)
    self[:balance_last_month] || self[:balance] - month_income + month_expenses
  end

  PERIODS = {
    month: 'month',
    week: 'week',
    day: 'day'
  }

  def money_flow(year, period)
    trunc = PERIODS.fetch(period) { raise ArgumentError, "Invalid period #{period}" }

    incoming = Transaction
      .where(to_account_id: id)
      .external
      .year(year)
      .group("DATE_TRUNC('#{trunc}', transaction_date)")
      .sum(:amount)
      .transform_keys { |date| date.to_date }

    outgoing = Transaction
      .where(from_account_id: id)
      .external
      .year(year)
      .group("DATE_TRUNC('#{trunc}', transaction_date)")
      .sum(:amount)
      .transform_keys { |date| date.to_date }

    all_periodes = case period
    when :month
      (1..12).map do |month| Date.new(year, month, 1) end
    when :week
      (1..Date.new(year).end_of_year.cweek).map do |week| Date.commercial(year, week, 1) end
    when :day
      Date.new(year).beginning_of_year..Time.current
    end

    summary = all_periodes.map do |p|
      {
        period: p,
        income: incoming[p] || 0,
        expenses: outgoing[p] || 0,
        net: (incoming[p] || 0) - (outgoing[p] || 0)
      }
    end

    {
      total: {
        income: incoming.values.sum,
        expenses: outgoing.values.sum,
        net: incoming.values.sum - outgoing.values.sum
      },
      incoming: incoming,
      outgoing: outgoing,
      all: summary
    }
  end

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

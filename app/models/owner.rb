class Owner < ApplicationRecord
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id'
  belongs_to :user, optional: true

  has_many :accounts, dependent: :destroy

  validates :user, comparison: { equal_to: :creator }, allow_nil: true

  scope :created_by_user, ->() { where(creator_id: Current.user) }

  def net_worth
    self[:net_worth] || accounts.sum(:balance)
  end

  def net_worth_last_month
    self[:net_worth_last_month] || accounts.sum(&:balance_last_month)
  end

  def recent_income
    self[:recent_income] || accounts.sum(&:recent_income)
  end

  def recent_expenses
    self[:recent_expenses] || accounts.sum(&:recent_expenses)
  end

  def previous_income
    self[:previous_income] || accounts.sum(&:previous_income)
  end

  def previous_expenses
    self[:previous_expenses] || accounts.sum(&:previous_expenses)
  end

  MONEY_FLOW_PERIODS = {
    month: 'month',
    week: 'week'
  }

  def money_flow(year, period)
    trunc = MONEY_FLOW_PERIODS.fetch(period) { raise ArgumentError, "Invalid period #{period}" }

    incoming = Transaction
      .where(to_account_id: accounts.select(:id))
      .external
      .year(year)
      .group("DATE_TRUNC('#{trunc}', transaction_date)")
      .sum(:amount)
      .transform_keys { |date| date.to_date }

    outgoing = Transaction
      .where(from_account_id: accounts.select(:id))
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

  HISTORY_PERIODS = {
    year: {
      trunc: 'year',
      range: ->() { 10.years.ago.beginning_of_year..Date.current },
      count: 10
    },
    month: {
      trunc: 'month',
      range: ->() { 12.months.ago.beginning_of_month..Date.current },
      count: 12
    }
  }

  def history(period)
    config = HISTORY_PERIODS.fetch(period) { raise ArgumentError, "Invalid period #{period}" }

    trunc = config[:trunc]
    range = config[:range].call
    count = config[:count]

    incoming = Transaction
      .external
      .where(to_account_id: accounts.select(:id))
      .where(transaction_date: range)
      .group("DATE_TRUNC('#{trunc}', transaction_date)")
      .sum(:amount)

    outgoing = Transaction
      .external
      .where(from_account_id: accounts.select(:id))
      .where(transaction_date: range)
      .group("DATE_TRUNC('#{trunc}', transaction_date)")
      .sum(:amount)

    history = []
    current_net_worth = net_worth

    timestamps = (0..count).map do |i|
      case period
      when :year then i.years.ago.beginning_of_year
      when :month then i.months.ago.beginning_of_month
      end
    end

    timestamps.map do |timestamp|
      net_in = incoming[timestamp] || 0
      net_out = outgoing[timestamp] || 0
      net_change = net_in - net_out

      history << { timestamp: timestamp, net_worth: current_net_worth, period_in: net_in, period_out: net_out, period_change: net_change }
      current_net_worth -= net_change
    end

    history.reverse
  end
end

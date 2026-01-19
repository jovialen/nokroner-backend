# frozen_string_literal: true

class BalanceBreakdownQuery
  def initialize(accounts:)
    @accounts = accounts
    @period = :quarter
    self
  end

  def for_period(start_date:, end_date:)
    @start_date = start_date
    @end_date = end_date
    self
  end

  def start_date(start_date)
    @start_date = start_date
    self
  end

  def end_date(end_date)
    @end_date = end_date
    self
  end

  def grouped_by(period)
    @period = period
    self
  end

  def execute
    BalanceBreakdownService.new(@accounts).calculate(
      start_date: @start_date,
      end_date: @end_date,
      period: @period
    )
  end
end

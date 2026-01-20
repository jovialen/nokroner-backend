class BalanceBreakdownService
  VALID_PERIODS = [ :week, :month, :quarter, :year ]
  TRUNC_PERIODS = { week: "week", month: "month", quarter: "quarter", year: "year" }

  def initialize(accounts)
    @accounts = accounts
  end

  # @summary Break down the sum balance of the accounts over time.
  # @param start_date [Date] First date of transaction to consider
  # @param end_date [Date] Last date of transaction to consider
  # @param period [Symbol] What time resolution to break down balance into
  # @return Sum balance of the accounts in the periods described by the input.
  def calculate(start_date:, end_date:, period: :month)
    validate_input!(start_date, end_date, period)

    # Parse the input
    trunc = TRUNC_PERIODS[period]

    # We need to know what the balance was at the end of the given time range,
    # since we are only working with the net change throughout, not the actual
    # balances. We get this initial balance by taking the current balance and
    # subtracting the net income since the end date.
    initial_balance = accounts_sum_balance - sum_trailing_transactions(after: end_date)

    # Get all transaction from one of the given accounts that don't go to
    # another one of the given accounts. invert_where inverts every "where"
    # statement before its called, so that's why the orderings weird.
    sent = Transaction.where(to_account: @accounts)
                      .invert_where
                      .where(from_account: @accounts)
                      .where(transaction_date: start_date..end_date)
                      .group("DATE_TRUNC('#{trunc}', transaction_date)")
                      .sum(:amount)
                      .transform_keys { |date| date.to_date }

    received = Transaction.where(from_account: @accounts)
                          .invert_where
                          .where(to_account: @accounts)
                          .where(transaction_date: start_date..end_date)
                          .group("DATE_TRUNC('#{trunc}', transaction_date)")
                          .sum(:amount)
                          .transform_keys { |date| date.to_date }

    all_start_periods = (sent.keys + received.keys).uniq
    if all_start_periods.empty?
      # If we don't have any transactions at all when we haven't even defined
      # a specific period, we might as well just declare that there is no
      # history.
      return []
    end

    # We also have to make the period well-defined at this point, in order to
    # stop ourselves from defining an infinite range for the possible periods.
    # We can set the unset bounds by selecting the earliest and latest period
    # we made a transaction in.
    start_date = all_start_periods.min.public_send("beginning_of_#{trunc}") unless start_date
    end_date   = all_start_periods.max.public_send("end_of_#{trunc}")       unless end_date

    # TODO: Prevent the start date from being automatically set after the end
    #       date, or the other way round.
    # TODO: Limit the duration of the period which can be requested
    # TODO: Prevent the start date or end date from being set in a way that
    #       creates an excessively long period.

    breakdown = generate_periods(start_date, end_date, period).reverse.map do | p |
      period_sent = sent[p[:start]] || BigDecimal(0)
      period_received = received[p[:start]] || BigDecimal(0)
      net_change = period_received - period_sent

      # We are working backwards from the end date, so the current balance must
      # be the balance at the end of the period, and the start balance must be
      # what the balance would be if we undo the net change of the period. This
      # will also update the current balance for the nest iteration. This does
      # however mean that manually editing the current balance of an account
      # will corrupt the history.
      end_balance = initial_balance
      initial_balance -= net_change

      {
        period_start: p[:start],
        period_end: p[:end],
        income: period_received,
        expenses: period_sent,
        net_change: net_change,
        initial_balance: initial_balance,
        end_balance: end_balance
      }
    end

    # Since we generated the breakdown in reverse, we have to reverse it again
    # in order to get the output in the expected order
    breakdown.reverse
  end

  private

  def validate_input!(start_date, end_date, period)
    raise ArgumentError, "start date cannot be later than end date" if start_date && end_date && start_date > end_date
    raise ArgumentError, "invalid period #{period}" unless VALID_PERIODS.include?(period)
  end

  def accounts_sum_balance
    # If there is only one account, just get its balance on its own. If there
    # are several accounts, sum them together in the database
    if @accounts.is_a? Account
      @accounts.balance
    else
      @accounts.sum(:balance)
    end
  end

  def sum_trailing_transactions(after)
    # If we haven't defined an end date, we want to include every transaction
    # from the start date onward, and as such, there will per definition be no
    # trailing transactions
    unless after
      return 0
    end

    # The sum of all transactions that go into and out of any account in the
    # given array will give us the net change for the sum balance of all the
    # accounts. Any internal transaction will self eliminate, so we don't need
    # to exclude them explicitly.
    income = Transaction.where(transaction_date: after..)
                        .where(to_account: @accounts)
                        .sum(:amount)

    expenses = Transaction.where(transaction_date: after..)
                          .where(from_account: @accounts)
                          .sum(:amount)

    income - expenses
  end

  def generate_periods(start_date, end_date, period)
    periods_start = start_date.public_send("beginning_of_#{period}")
    periods_end = end_date.public_send("end_of_#{period}")

    step = case period
    when :quarter then 3.months
    else 1.public_send(period)
    end

    (periods_start..periods_end).step(step).map do | period_start |
      period_end = period_start.public_send("end_of_#{period}")

      {
        start: [ period_start, start_date ].max,
        end: [ period_end, end_date ].min
      }
    end
  end
end

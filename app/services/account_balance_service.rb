class AccountBalanceService
  def initialize(account)
    @account = account
  end

  def update_balance(to)
    update_balance_at(Date.today, to)
  end

  def update_balance_at(date, balance)
    delta = balance - @account.balance_at(date)
    change_at(date, delta)
  end

  def change(by)
    change_at(Date.today, by)
  end

  def change_at(date, by)
    ApplicationRecord.transaction requires_new: true do
      @account.balance_snapshots
        .at_or_after(date)
        .update_all("balance = balance + #{by}")

      unless @account.balance_snapshots.find_by(date: date)
        @account.balance_snapshots.create!(date: date, balance: @account.balance_at(date) + by)
      end
    end
  end
end

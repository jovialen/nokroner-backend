class AccountBalanceService
  def self.update_balance(account, to)
    update_balance_at(account, Date.today, to)
  end

  def self.update_balance_at(account, date, to)
    new(account).update_balance_at(date, to)
  end

  def self.change(account, by)
    change_at(account, Date.today, by)
  end

  def self.change_at(account, date, by)
    new(account).change_at(date, by)
  end

  def initialize(account)
    @account = account
  end

  def update_balance(to)
    update_balance_at(Date.today, to)
  end

  def update_balance_at(date, to)
    date ||= Date.today

    delta = to - @account.balance_at(date)
    change_at(date, delta)
  end

  def change(by)
    change_at(Date.today, by)
  end

  def change_at(date, by)
    date ||= Date.today

    ApplicationRecord.transaction do
      @account.balance_snapshots
        .at_or_after(date)
        .update_all("balance = balance + #{by}")

      unless @account.balance_snapshots.find_by(date: date)
        @account.balance_snapshots.create!(date: date, balance: @account.balance_at(date) + by)
      end
    end
  end
end

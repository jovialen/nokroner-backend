class Account < ApplicationRecord
  belongs_to :owner, class_name: "Group"
  has_many :balance_snapshots, class_name: "AccountBalanceSnapshot", foreign_key: "account_id", dependent: :destroy

  validate :owner_belongs_to_user, if: -> { owner.present? }

  def balance
    balance_at(Date.today)
  end

  def balance_at(date)
    balance_snapshots.at_or_before(date).order(date: :desc).take&.balance || BigDecimal(0)
  end

  def as_json(options = {})
    date = options[:at] || Date.today

    super(options).merge(
      balance: balance_at(date)
    )
  end

  private

  def owner_belongs_to_user
    unless owner.created_by == Current.user
      # Let's not reveal if the group exists or not
      errors.add(:owner, "doesn't exist")
    end
  end
end

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
end

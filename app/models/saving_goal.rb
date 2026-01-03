class SavingGoal < ApplicationRecord
  belongs_to :user

  validates :amount, comparison: { greater_than_or_equal_to: 0.0 }

  scope :created_by_user, ->() { where(user_id: Current.user) }
  scope :realized, ->() { where(realized: true) }

  def saved
    allocated = SavingGoal.created_by_user
      .realized
      .sum(:amount)
    
    balance = user.owner.balance

    (balance - allocated).clamp(0, amount)
  end
end

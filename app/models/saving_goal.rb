class SavingGoalValidator < ActiveModel::Validator
  def validate(record)
    if record.realized
      if record.real_saved < record.amount
        record.errors.add :realized, 'must have saved the required amount'
      end
    end

    if record.archived && !record.realized
      record.errors.add :archived, 'cannot archive incomplete saving goal'
    end
  end
end

class SavingGoal < ApplicationRecord
  belongs_to :user

  validates :amount, comparison: { greater_than_or_equal_to: 0.0 }

  validates_with SavingGoalValidator

  scope :created_by_user, ->() { where(user_id: Current.user) }
  scope :realized, ->() { where(realized: true) }
  scope :current, ->() { where(archived: [false, nil]) }

  def saved
    if realized || archived then
      amount
    else
      real_saved
    end
  end

  def ready
    saved >= amount || realized
  end

  private

  def real_saved
    allocated = SavingGoal.created_by_user
      .realized
      .current
      .sum(:amount)
    
    balance = user.owner.balance

    (balance - allocated).clamp(0, amount)
  end
end

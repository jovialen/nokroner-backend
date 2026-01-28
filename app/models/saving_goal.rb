class SavingGoal < ApplicationRecord
  # Users make saving goals
  belongs_to :user

  # In order to differentiate the saving goals, names should be unique
  validates :name, presence: true, uniqueness: { scope: :user }

  # Every saving goal has to have an amount it is saving towards, and since it
  # doesn't make sense to save a negative amount, enforce that the amount must
  # be greater than zero.
  validates :amount, presence: true, numericality: { greater_than: 0 }

  # We also have to ensure that the user cannot set a saving goal as done
  # unless they actually have the funds for it
  validate :has_enough_saved, on: [ :create, :update ]

  # These scopes are also just generally useful
  scope :created_by_user, ->() { where(user: Current.user) }
  scope :completed, ->() { where(done: true) }
  scope :archived, ->() { where(archived: true) }

  def saved
    # The amount of saved money is equal to the users balance minus the money
    # reserved by other spending goals. However, if the saving goal has already
    # been completed, its amount is already included in the reserved amount, so
    # we can just assume that the user had enough money.
    if done
      amount
    else
      BigDecimal((user.owner.balance - reserved).clamp(0, amount))
    end
  end

  private

  def reserved
    # Get the sum of the completed saving goals amount which haven't been
    # archived. The ordering is a bit strange because "invert_where" inverts
    # all "where" before it.
    # We also exclude the saving goal which is making the call, as it
    # simplifies the validation.
    SavingGoal.archived
              .where(id: id)
              .invert_where
              .created_by_user
              .completed
              .sum(:amount)
  end

  def has_enough_saved
    if done && (user.owner.balance - reserved) < amount
      errors.add(:done, "can only be true once the required amount has been saved")
    end
  end
end

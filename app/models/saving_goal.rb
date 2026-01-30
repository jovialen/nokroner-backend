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

  # If the goal can be autocompleted, we want to do so before saving.
  before_validation :autocomplete_if_possible

  # These scopes are also just generally useful
  scope :created_by_user, ->() { where(user: Current.user) }
  scope :completed, ->() { where(done: true) }
  scope :archived, ->() { where(archived: true) }

  # @summary How much money the user has saved
  #
  # The amount of saved money is equal to the users balance minus the money
  # reserved by other spending goals. However, if the saving goal has already
  # been completed, its amount is already included in the reserved amount, so
  # we can just assume that the user had enough money.
  #
  # @return Saved amount.
  def saved
    if done
      amount
    else
      BigDecimal((user.owner.balance - reserved).clamp(0, amount))
    end
  end

  # @summary Remaining amount to save
  # Takes the saving goal amount and subtracts the saved amount.
  def remaining
    amount - saved
  end

  # @summary If the saving goal is ready to be completed.
  # @return True if the required amount has been saved
  def ready
    saved >= amount
  end

  # @summary How much the user must save every day to meet the goal by the target date.
  #
  # The amount the user has to save on a daily basis is equal to the remaining amount
  # divided by the amount of days left to save. If there is no target date, this
  # function simply returns nil.
  #
  # @return Daily required saving amount.
  def daily_saving
    if target_date.nil?
      return nil
    end

    days = (target_date - Date.today).to_i

    if days > 0
      amount / days
    else
      amount
    end
  end

  private

  def reserved
    # Get the sum of the completed saving goals amount which haven't been
    # archived. The ordering is a bit strange because "invert_where" inverts
    # all "where" before it.
    # We also exclude the saving goal which is making the call, as it
    # simplifies the validation.
    reserved_by_complete = SavingGoal.created_by_user
                                     .where.not(id: id)
                                     .where(done: true, archived: false)
                                     .sum(:amount)

    # Also get the sum of all higher priority saving goals, since this saving
    # goal cannot be saved for before they've been saved for first.
    reserved_by_priority = SavingGoal.created_by_user
                                     .where.not(id: id)
                                     .where(done: false, archived: false)
                                     .where("priority < ?", priority)
                                     .sum(:amount)

    reserved_by_complete + reserved_by_priority
  end

  def autocomplete_if_possible
    if autocomplete && amount > 0 && ready
      self.done = true
    end
  end

  def has_enough_saved
    if done && (user.owner.balance - reserved) < amount
      errors.add(:done, "can only be true once the required amount has been saved")
    end
  end
end

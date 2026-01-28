class SavingGoalAutocompleteJob < ApplicationJob
  queue_as :default

  def perform(user)
    # Find the amount available for saving goals to spend
    total_balance = user.owner.balance
    already_allocated = SavingGoal.where(user: user)
                                  .where(done: true, archived: false)
                                  .sum(:amount)
    available = total_balance - already_allocated

    # Complete as many saving goals as possible with the available funds, but
    # don't autocomplete goals that haven't been marked for autocompletion
    SavingGoal.where(user: user)
              .where(autocomplete: true, done: false, archived: false)
              .order(:target_date, :created_at)
              .lock
              .each do |goal|
      # Check if the goal is complete
      if goal.amount <= available
        # And if it is, complete it and reduce the available funds by the
        # amount of the saving goal, as it's now allocated.
        goal.update!(done: true)
        available -= goal.amount
      end
    end
  end
end

class SavingGoalAutocompleteJob < ApplicationJob
  queue_as :default

  def perform(user)
    ActiveRecord::Base.transaction do
      # Find the amount available for saving goals to spend
      total_balance = user.owner.balance
      already_allocated = SavingGoal.where(user: user)
                                    .where(done: true, archived: false)
                                    .sum(:amount)
      available = total_balance - already_allocated

      # Save all completable saving goals
      completable = []

      # Also set a priority the saving goal must surpass to be considered
      max_priority = nil

      # Complete as many saving goals as possible with the available funds, but
      # don't autocomplete goals that haven't been marked for autocompletion.
      # Also make sure that we attempt to complete the prioritized goals first.
      SavingGoal.where(user: user)
                .where(autocomplete: true, done: false, archived: false)
                .order(:priority, :target_date, :created_at)
                .lock
                .each do |goal|
        # Skip goals that don't meet the priority requirements
        break if max_priority.present? && goal.priority > max_priority

        # Check if the goal is complete
        if goal.amount <= available
          # And if it is, complete it and reduce the available funds by the
          # amount of the saving goal, as it's now allocated.
          completable << goal.id
          available -= goal.amount
        else
          # If it isn't, set the goals priority as the last priority to be
          # considered.
          max_priority = goal.priority
        end
      end

      # Batch complete all completable goals
      SavingGoal.where(id: completable).update_all(done: true) if completable.any?
    end
  end
end

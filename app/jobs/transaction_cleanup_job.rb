class TransactionCleanupJob < ApplicationJob
  queue_as :low_priority

  def perform(*args)
    # Find and delete any transactions that do not apply to any accounts
    Transaction.where.missing(:to, :from).destroy_all
  end
end

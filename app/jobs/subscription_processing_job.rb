class SubscriptionProcessingJob < ApplicationJob
  queue_as :default

  def perform(*args)
    for s in Subscription.where(next_run_at: ..Time.now, autorun: true)
      ApplicationRecord.transaction do
        t = s.next_transaction
        s.set_next_run

        TransactionService.new(t).perform
        t.save!
        s.save!
      end
    end
  end
end

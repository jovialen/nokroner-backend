class Subscription < ApplicationRecord
  belongs_to :from, class_name: "Account"
  belongs_to :to, class_name: "Account"

  has_many :transactions, dependent: :nullify

  before_validation :set_next_run

  validate :belongs_to_user
  validate :valid_cron

  def next_transaction
    Transaction.new(name: "#{name} #{next_run_at}",
      from: from,
      to: to,
      date: next_run_at,
      amount: amount,
      subscription: self
    )
  end

  def as_cron
  Fugit::Cron.parse(self.cron)
  end

  def set_next_run
    self.next_run_at = as_cron.next_time.to_s
  end

  private

  def belongs_to_user
    unless from.present? && from.owner.created_by == Current.user
      errors.add(:from, "must be a valid account")
    end

    unless to.present? && to.owner.created_by == Current.user
      errors.add(:to, "must be a valid account")
    end
  end

  def valid_cron
    parsed = Fugit::Cron.parse(cron)

    if parsed.nil?
      errors.add(:cron, "is not a valid cron expression")
    end
  end
end

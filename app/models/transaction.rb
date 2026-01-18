class Transaction < ApplicationRecord
  # In order to not have to sum all transactions for an account every time we
  # want to know its balance, keep the accounts updated with their proper
  # current balance by modifying them when transactions are added.
  after_create :perform_transaction
  before_destroy :undo_transaction

  # Also, in order for the balance to be correct even if we change the amount
  # of the transaction, when we update the transaction, we first need to undo
  # the transaction before changing the amount, and then performing it anew
  # with the new amount
  before_update :undo_transaction
  after_update :perform_transaction

  # Also cache if the transaction is internal or not when it's created or
  # updated, so that we can query it later.
  before_validation :check_if_external, on: [ :create, :update ]

  # Every transaction has to have a user they belong to so that they can be
  # destroyed together and keep the database clean
  belongs_to :created_by, class_name: "User", foreign_key: :created_by_id

  # A transaction is made between two accounts, of which there is no
  # dependency, so that either account can safely be destroyed without also
  # destroying the transaction and changing the balance of the other account.
  belongs_to :from_account, class_name: "Account", foreign_key: :from_account_id, optional: true
  belongs_to :to_account, class_name: "Account", foreign_key: :to_account_id, optional: true

  # And since the "to" and "from" accounts are set explicitly, negative
  # transfers are disallowed, as well as transactions of unknown amounts, which
  # would not make sense.
  validates :amount, presence: true, numericality: { greater_than: 0 }

  # For simplicities’ sake, we also don't want to allow "future" transactions
  validates :transaction_date, comparison: { less_than_or_equal_to: -> { Date.today } }

  # It also does not make sense to have a transaction that has the same "to"
  # and "from" account, as it would be completely unnecessary
  validate :accounts_must_be_different

  # And since we are just interested in the personal finance aspect of the app,
  # we don't need to keep track of transactions that don't involve the user
  validate :transaction_involves_user

  # We need to know which user created the transaction, so that the transaction
  # can be destroyed together with the user if the user is destroyed. Since it
  # should be possible to destroy either one of the accounts the transaction
  # belongs to without destroying the transaction and corrupting the record of
  # the other account, this records lifetime cannot depend on either account.
  scope :created_by_user, ->() { where(created_by: Current.user) }

  # We may be interested in transactions involving a specific owner
  scope :sent_from_owner, ->(owner) { where(from_account: owner.accounts) }
  scope :received_by_owner, ->(owner) { where(to_account: owner.accounts) }

  # Or we might alternatively be interested in transactions between specific
  # accounts
  scope :sent_from_account, ->(account) { where(from_account: account) }
  scope :received_by_account, ->(account) { where(to_account: account) }

  # We might likewise be interested exclusively in transactions between
  # accounts owned by the same owner, or exclusively different owners.
  # That is, internal transactions and external transactions
  scope :external, ->() { where(external: true) }
  scope :internal, ->() { where(external: false) }

  # There are also a lot of valuable time considerations that should be easily
  # available
  scope :today, ->() { where(transaction_date: Date.today) }
  scope :this_week, ->() { where(transaction_date: Date.today.beginning_of_week) }
  scope :this_month, ->() { where(transaction_date: Date.today.beginning_of_month..Date.today.end_of_month) }
  scope :this_quarter, ->() { where(transaction_date: Date.today.beginning_of_quarter..Date.today.end_of_quarter) }
  scope :this_year, ->() { where(transaction_date: Date.today.beginning_of_year..Date.today.end_of_year) }

  private

  def perform_transaction
    Rails.logger.info "Performing transaction: #{amount} from #{from_account&.id} to #{to_account&.id}"

    # Only apply the transaction if we succeed both at withdrawing the amount
    # from one account and then depositing it. This ensures that no database
    # errors either create or destroy money.
    ActiveRecord::Base.transaction do
      from_account.withdraw!(amount) if from_account.present?
      to_account.deposit!(amount) if to_account.present?
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      errors.add(:base, "failed to perform transaction: #{e.message}")
      raise ActiveRecord::Rollback
    end
  end

  def undo_transaction
    # See previous comment
    ActiveRecord::Base.transaction do
      from_account.deposit!(amount) if from_account.present?
      to_account.withdraw!(amount) if to_account.present?
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
      errors.add(:base, "failed to undo transaction: #{e.message}")
      raise ActiveRecord::Rollback
    end
  end

  # The following are just validation functions, whose purpose is explained over.

  def accounts_must_be_different
    if from_account_id == to_account_id
      errors.add(:to_account_id, "can't be the same as from_account")
    end
  end

  def transaction_involves_user
    # Ensure that at least one of the accounts is present, otherwise we aren't
    # interested in a transaction between two unknown accounts
    if from_account.blank? && to_account.blank?
      errors.add(:base, "to and from account can't both be blank")
    end

    user_owner_id = Current.user.owner_id

    # If the account is not known, assume that it doesn't belong to the user
    user_owns_from_account = from_account.present? && from_account.owner_id == user_owner_id
    user_owns_to_account = to_account.present? && to_account.owner_id == user_owner_id

    # If neither account belongs to the user, then we aren't interested in
    # the transaction either.
    if !user_owns_from_account && !user_owns_to_account
      errors.add(:base, "neither to or from account belongs to the user")
    end
  end

  def check_if_external
    if from_account.present? && to_account.present?
      # Transactions are external if they are between two accounts with
      # different owners.
      self.external = from_account.owner_id != to_account.owner_id
    else
      # If one account is missing, assume that the unknown account has
      # a different owner than the well-defined account.
      self.external = true
    end
  end
end

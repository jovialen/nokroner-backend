class Transaction < ApplicationRecord
  belongs_to :created_by, class_name: "User", foreign_key: :created_by_id

  belongs_to :from_account, class_name: "Account", foreign_key: :from_account_id
  belongs_to :to_account, class_name: "Account", foreign_key: :to_account_id

  validates :amount, presence: true, numericality: { greater_than: 0 }

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
end

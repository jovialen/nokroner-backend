class Account < ApplicationRecord
  # Every account belongs to an owner
  belongs_to :owner
  has_one :created_by, class_name: "User", through: :owner

  # And every account has many transactions either into or out of the account.
  # These transactions are not dependent on either account, since either one
  # should potentially could be destroyed without affecting the other one.
  has_many :sent_transactions, class_name: "Transaction", foreign_key: :from_account_id
  has_many :received_transactions, class_name: "Transaction", foreign_key: :to_account_id

  # The name and account number of the account should also be unique on a
  # per-user basis. Optimally, the account number should be unique for an
  # entire user, not just for the owner, but this is easier and works
  # well enough for my purposes.
  validates :name, presence: true, uniqueness: { scope: :owner_id }
  validates :account_number, uniqueness: { scope: :owner_id }

  # We also want to be able to quickly get all accounts created by the current
  # user
  scope :created_by_user, ->() { left_joins(:owner).where("created_by_id = ?", Current.user.id) }

  # Sometimes, we just want to get all transactions related to the account,
  # in or out
  def transactions
    Transaction.where("from_account_id = ? OR to_account_id = ?", id, id)
  end
end

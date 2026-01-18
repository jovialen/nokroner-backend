class Account < ApplicationRecord
  # Every account belongs to an owner
  belongs_to :owner

  # The name and account number of the account should also be unique on a
  # per-user basis. Optimally, the account number should be unique for an
  # entire user, not just for the owner, but this is easier and works
  # well enough for my purposes.
  validates :name, presence: true, uniqueness: { scope: :owner_id }
  validates :account_number, uniqueness: { scope: :owner_id }

  # We also want to be able to quickly get all accounts created by the current
  # user
  scope :created_by_user, ->() { left_joins(:owner).where("created_by_id = ?", Current.user.id) }
end

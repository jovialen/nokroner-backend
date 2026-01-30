class Owner < ApplicationRecord
  # An owner is created by and therefore belongs to a user
  belongs_to :created_by, class_name: "User", foreign_key: :created_by_id

  # The owner might also be the user owner, which is referred to as such
  has_one :user, foreign_key: :owner_id

  # Every owner must have a name
  validates :name, presence: true

  # Owners all belong to a creator user, and every account must belong to a
  # user. By destroying an owners accounts with the owner, when a user is
  # destroyed, all the accounts the user has created will be destroyed with
  # it.
  has_many :accounts, dependent: :destroy

  # Common queries for an owner
  scope :created_by_user, ->() { where(created_by: Current.user) }

  # An important statistic for all owners is their balance, which is the
  # sum of all their accounts balances.
  def balance
    accounts.sum(:balance)
  end
end

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_one :owner, dependent: :destroy
  has_many :accounts, through: :owner

  has_many :created_owners, class_name: "Owner", foreign_key: "creator_id", dependent: :destroy
  has_many :created_accounts, through: :created_owners, source: :accounts
  has_many :created_transactions, class_name: "Transaction", foreign_key: "creator_id", dependent: :destroy

  validates :owner, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end

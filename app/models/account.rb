class Account < ApplicationRecord
  belongs_to :owner

  validates :account_number, uniqueness: true
end

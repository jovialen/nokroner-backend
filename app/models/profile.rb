class Profile < ApplicationRecord
  belongs_to :user

  validates :first_name, presence: true
  validates :date_of_birth, presence: true

  def full_name
    [ first_name, last_name ].join(" ")
  end

  def is_old_enough?
    age >= 18
  end

  def age
    a = Date.today.year - date_of_birth.year
    a = a - 1 if date_of_birth.month > Date.today.month or
        (date_of_birth.month >= Date.today.month and date_of_birth.day > Date.today.day)
    a
  end
end

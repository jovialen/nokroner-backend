class User < ApplicationRecord
  # User authentication
  normalizes :email_address, with: ->(e) { e.strip.downcase }
  has_secure_password
  has_many :sessions, dependent: :destroy

  # User profile
  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile
  validates :profile, presence: true

  # Every user is also one owner
  belongs_to :owner, optional: true
  accepts_nested_attributes_for :owner
  validates :owner, presence: true
  before_validation :build_owner_if_needed, on: :create
  before_validation :set_owner_name_from_profile, on: [ :create, :update ]

  # Users can also make saving goals
  has_many :saving_goals, dependent: :destroy

  # Database data dependent on the user, and which should be deleted with the
  # user if its deleted
  has_many :owners, dependent: :destroy
  has_many :transactions, dependent: :destroy

  private

  def build_owner_if_needed
    if owner.blank?
      self.owner = Owner.new(created_by: self, name: profile.full_name)
    end
  end

  def set_owner_name_from_profile
    if owner.present? && profile.present?
      owner.name = profile.full_name
    end
  end
end

class Group < ApplicationRecord
  belongs_to :created_by, class_name: "User"

  belongs_to :parent, class_name: "Group", optional: true
  has_many :children, class_name: "Group", foreign_key: "parent_id"

  validate :valid_parent, if: -> { parent.present? }

  def as_json(options = {})
    super(options.merge(except: :created_by_id))
  end

  private

  def valid_parent
    unless parent.created_by == created_by
      errors.add(:parent, "must be created by the same user")
    end

    if parent.id == self.id
      errors.add(:parent, "cannot be self")
    end

    if created_by.group_id == self.id
      errors.add(:group, "cannot have a parent")
    end
  end
end

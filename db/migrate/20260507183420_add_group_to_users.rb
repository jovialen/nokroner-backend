class AddGroupToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :group_id, :bigint
    add_foreign_key :users, :groups, deferrable: :deferred
    change_column_null :users, :group_id, true
  end
end

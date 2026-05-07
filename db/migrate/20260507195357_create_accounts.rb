class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name
      t.belongs_to :owner, null: false, foreign_key: { to_table: :groups }

      t.timestamps
    end
  end
end

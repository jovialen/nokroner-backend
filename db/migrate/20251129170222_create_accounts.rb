class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :account_number, null: false
      t.string :name, null: false
      t.float :balance, null: false
      t.float :interest, null: false

      t.references :owner, foreign_key: true, null: true
      t.references :creator, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end
  end
end

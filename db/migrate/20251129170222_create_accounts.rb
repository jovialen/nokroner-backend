class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :account_number
      t.string :name
      t.float :balance
      t.float :interest

      t.references :owner, foreign_key: true, null: false

      t.timestamps
    end
  end
end

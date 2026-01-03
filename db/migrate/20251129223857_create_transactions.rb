class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :name
      t.float :amount
      t.date :transaction_date

      t.references :from_account, foreign_key: { to_table: :accounts }, null: false
      t.references :to_account, foreign_key: { to_table: :accounts }, null: false
      t.references :creator, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end

    add_index :transactions, [:from_account_id, :to_account_id, :transaction_date, :creator_id]
  end
end

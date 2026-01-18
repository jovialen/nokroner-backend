class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :name
      t.decimal :amount, null: false
      t.references :from_account, null: false, foreign_key: { to_table: :accounts }
      t.references :to_account, null: false, foreign_key: {  to_table: :accounts }
      t.date :transaction_date, null: false
      t.belongs_to :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :transactions, :transaction_date
  end
end

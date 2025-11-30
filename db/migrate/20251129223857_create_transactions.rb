class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :name
      t.float :amount

      t.references :from_account, foreign_key: { to_table: :accounts }, null: false
      t.references :to_account, foreign_key: { to_table: :accounts }, null: false
      t.references :creator, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end
  end
end

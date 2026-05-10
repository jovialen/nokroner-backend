class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions do |t|
      t.string :name
      t.decimal :amount
      t.references :from, null: false, foreign_key: { to_table: :accounts }
      t.references :to, null: false, foreign_key: { to_table: :accounts }
      t.date :date, null: false, default: -> { 'CURRENT_DATE' }

      t.timestamps
    end
  end
end

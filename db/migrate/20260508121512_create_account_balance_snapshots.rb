class CreateAccountBalanceSnapshots < ActiveRecord::Migration[8.1]
  def change
    create_table :account_balance_snapshots, primary_key: [ :date, :account_id ] do |t|
      t.date :date
      t.belongs_to :account, null: false, foreign_key: true
      t.decimal :balance

      t.timestamps
    end
  end
end

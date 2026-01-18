class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :account_number
      t.decimal :balance, null: false, default: 0
      t.belongs_to :owner, null: false, foreign_key: true

      t.timestamps
    end
  end
end

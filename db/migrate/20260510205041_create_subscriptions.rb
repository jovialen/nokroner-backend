class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.string :name
      t.references :from, null: false, foreign_key: { to_table: :accounts }
      t.references :to, null: false, foreign_key: { to_table: :accounts }
      t.decimal :amount
      t.string :cron
      t.boolean :autorun, default: true
      t.timestamp :next_run_at

      t.timestamps
    end

    add_reference :transactions, :subscription, null: true, foreign_key: true
  end
end

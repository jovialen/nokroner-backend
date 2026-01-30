class CreateSavingGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :saving_goals do |t|
      t.string :name, null: false
      t.decimal :amount, null: false
      t.integer :priority, null: false, default: 0
      t.boolean :autocomplete, null: false, default: false
      t.boolean :done, default: false
      t.boolean :archived, default: false
      t.belongs_to :user, null: false, foreign_key: true
      t.date :target_date

      t.timestamps
    end
  end
end

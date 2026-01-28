class CreateSavingGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :saving_goals do |t|
      t.string :name, null: false
      t.decimal :amount, null: false
      t.boolean :done, default: false
      t.boolean :archived, default: false
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

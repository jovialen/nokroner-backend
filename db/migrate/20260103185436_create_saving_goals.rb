class CreateSavingGoals < ActiveRecord::Migration[8.1]
  def change
    create_table :saving_goals do |t|
      t.string :name
      t.float :amount
      t.boolean :realized
      t.boolean :archived
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

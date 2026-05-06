class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.references :parent, foreign_key: { to_table: :groups }, null: true
      t.belongs_to :created_by, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end
  end
end

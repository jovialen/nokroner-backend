class CreateOwners < ActiveRecord::Migration[8.1]
  def change
    create_table :owners do |t|
      t.string :name, null: false

      t.references :user, foreign_key: true, null: true
      t.references :creator, foreign_key: { to_table: :users }, null: false

      t.timestamps
    end
  end
end

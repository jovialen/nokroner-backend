class CreateOwners < ActiveRecord::Migration[8.1]
  def change
    create_table :owners do |t|
      t.string :name
      t.references :created_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_reference :users, :owner, null: true, foreign_key: true
  end
end

class CreateAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :accounts do |t|
      t.string :name
      t.text :description
      t.float :balance

      t.timestamps
    end
  end
end

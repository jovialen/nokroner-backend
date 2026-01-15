class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :ip_address
      t.string :user_agent
      t.string :auth_token, null: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :sessions, :auth_token, unique: true
  end
end

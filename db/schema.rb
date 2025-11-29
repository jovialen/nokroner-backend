# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_29_223857) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "account_number"
    t.float "balance"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.float "interest"
    t.string "name"
    t.bigint "owner_id"
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_accounts_on_creator_id"
    t.index ["owner_id"], name: "index_accounts_on_owner_id"
  end

  create_table "owners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.boolean "is_user"
    t.string "name"
    t.float "net_worth"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["creator_id"], name: "index_owners_on_creator_id"
    t.index ["user_id"], name: "index_owners_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.float "amount"
    t.datetime "created_at", null: false
    t.bigint "creator_id", null: false
    t.bigint "from_account_id_id", null: false
    t.string "name"
    t.bigint "to_account_id_id", null: false
    t.datetime "updated_at", null: false
    t.index ["creator_id"], name: "index_transactions_on_creator_id"
    t.index ["from_account_id_id"], name: "index_transactions_on_from_account_id_id"
    t.index ["to_account_id_id"], name: "index_transactions_on_to_account_id_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "accounts", "owners"
  add_foreign_key "accounts", "users", column: "creator_id"
  add_foreign_key "owners", "users"
  add_foreign_key "owners", "users", column: "creator_id"
  add_foreign_key "sessions", "users"
  add_foreign_key "transactions", "accounts", column: "from_account_id_id"
  add_foreign_key "transactions", "accounts", column: "to_account_id_id"
  add_foreign_key "transactions", "users", column: "creator_id"
end

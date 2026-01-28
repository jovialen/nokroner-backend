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

ActiveRecord::Schema[8.1].define(version: 2026_01_19_100920) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "account_number"
    t.decimal "balance", default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_accounts_on_owner_id"
  end

  create_table "owners", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_owners_on_created_by_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date_of_birth", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "saving_goals", force: :cascade do |t|
    t.decimal "amount", null: false
    t.boolean "archived", default: false
    t.datetime "created_at", null: false
    t.boolean "done", default: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_saving_goals_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "auth_token", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["auth_token"], name: "index_sessions_on_auth_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "transactions", force: :cascade do |t|
    t.decimal "amount", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id", null: false
    t.boolean "external", null: false
    t.bigint "from_account_id"
    t.string "name"
    t.bigint "to_account_id"
    t.date "transaction_date", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_transactions_on_created_by_id"
    t.index ["from_account_id"], name: "index_transactions_on_from_account_id"
    t.index ["to_account_id"], name: "index_transactions_on_to_account_id"
    t.index ["transaction_date"], name: "index_transactions_on_transaction_date"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.bigint "owner_id"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["owner_id"], name: "index_users_on_owner_id"
  end

  add_foreign_key "accounts", "owners"
  add_foreign_key "owners", "users", column: "created_by_id"
  add_foreign_key "profiles", "users"
  add_foreign_key "saving_goals", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "transactions", "accounts", column: "from_account_id"
  add_foreign_key "transactions", "accounts", column: "to_account_id"
  add_foreign_key "transactions", "users", column: "created_by_id"
  add_foreign_key "users", "owners"
end

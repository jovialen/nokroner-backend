require "test_helper"

class Api::V1::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post api_v1_login_path, params: { email_address: users(:one).email_address, password: "password" }, as: :json
    assert_response :success, "failed to log into user"
  end

  # Index tests
  test "should get all accounts for current user" do
    get api_v1_accounts_path, as: :json
    assert_response :success

    accounts = JSON.parse(response.body)
    assert_equal 3, accounts.length, "should return 3 accounts owned by current user"

    account_ids = accounts.map { |a| a["id"] }
    assert_includes account_ids, accounts(:checking).id
    assert_includes account_ids, accounts(:savings).id
    assert_includes account_ids, accounts(:other_owner_account).id
    assert_not_includes account_ids, accounts(:other_user_account).id
  end

  test "should get accounts filtered by owner" do
    get api_v1_owner_accounts_path(owners(:one)), as: :json
    assert_response :success

    accounts = JSON.parse(response.body)
    assert_equal 2, accounts.length, "should return 2 accounts for owner one"

    accounts.each do |account|
      assert_equal owners(:one).id, account["owner_id"]
    end
  end

  test "should not get accounts for other user's owner" do
    get api_v1_owner_accounts_path(owners(:other_user_owner)), as: :json
    assert_response :not_found
  end

  # Show tests
  test "should get account" do
    get api_v1_account_path(accounts(:checking)), as: :json
    assert_response :success

    account = JSON.parse(response.body)
    assert_equal accounts(:checking).id, account["id"]
    assert_equal accounts(:checking).name, account["name"]
    assert_equal accounts(:checking).account_number, account["account_number"]
  end

  test "should get account within owner scope" do
    get api_v1_owner_account_path(owners(:one), accounts(:checking)), as: :json
    assert_response :success

    account = JSON.parse(response.body)
    assert_equal accounts(:checking).id, account["id"]
  end

  test "should not get account from different owner when using owner scope" do
    get api_v1_owner_account_path(owners(:one), accounts(:other_owner_account)), as: :json
    assert_response :not_found
  end

  test "should not get account created by another user" do
    get api_v1_account_path(accounts(:other_user_account)), as: :json
    assert_response :not_found
  end

  # Create tests
  test "should create account" do
    assert_difference("Account.count") do
      post api_v1_accounts_path, params: {
        account: {
          name: "New Account",
          account_number: "5555555555",
          balance: 500.00,
          owner_id: owners(:one).id
        }
      }, as: :json
      assert_response :created
    end

    account = JSON.parse(response.body)
    assert_equal "New Account", account["name"]
    assert_equal "5555555555", account["account_number"]
    assert_equal "500.0", account["balance"]
    assert_equal owners(:one).id, account["owner_id"]
  end

  test "should create account within owner scope" do
    assert_difference("Account.count") do
      post api_v1_owner_accounts_path(owners(:one)), params: {
        account: {
          name: "Owner Scoped Account",
          account_number: "6666666666",
          balance: 750.00
        }
      }, as: :json
      assert_response :created
    end

    account = JSON.parse(response.body)
    assert_equal "Owner Scoped Account", account["name"]
    assert_equal owners(:one).id, account["owner_id"]
  end

  test "should not create account with invalid params" do
    assert_no_difference("Account.count") do
      post api_v1_accounts_path, params: {
        account: {
          name: nil,
          account_number: "7777777777",
          balance: 100.00,
          owner_id: owners(:one).id
        }
      }, as: :json
      assert_response :unprocessable_entity
    end

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")
    assert_kind_of Array, response_body["errors"]
  end

  test "should not create account for other user's owner" do
    assert_no_difference("Account.count") do
      post api_v1_accounts_path, params: {
        account: {
          name: "Unauthorized Account",
          account_number: "8888888888",
          balance: 100.00,
          owner_id: owners(:other_user_owner).id
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should not create account with duplicate name for same owner" do
    assert_no_difference("Account.count") do
      post api_v1_accounts_path, params: {
        account: {
          name: accounts(:checking).name,
          account_number: "9999999999",
          balance: 100.00,
          owner_id: owners(:one).id
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should not create account with duplicate account number for same owner" do
    assert_no_difference("Account.count") do
      post api_v1_accounts_path, params: {
        account: {
          name: "Different Name",
          account_number: accounts(:checking).account_number,
          balance: 100.00,
          owner_id: owners(:one).id
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  # Update tests
  test "should update account" do
    patch api_v1_account_path(accounts(:checking)), params: {
      account: { name: "Updated Checking Account" }
    }, as: :json
    assert_response :success

    account = JSON.parse(response.body)
    assert_equal "Updated Checking Account", account["name"]

    accounts(:checking).reload
    assert_equal "Updated Checking Account", accounts(:checking).name
  end

  test "should update account balance" do
    patch api_v1_account_path(accounts(:checking)), params: {
      account: { balance: 1500.00 }
    }, as: :json
    assert_response :success

    accounts(:checking).reload
    assert_equal 1500.00, accounts(:checking).balance.to_f
  end

  test "should update account within owner scope" do
    patch api_v1_owner_account_path(owners(:one), accounts(:checking)), params: {
      account: { name: "Owner Scoped Update" }
    }, as: :json
    assert_response :success

    accounts(:checking).reload
    assert_equal "Owner Scoped Update", accounts(:checking).name
  end

  test "should not update account with invalid params" do
    original_name = accounts(:checking).name

    patch api_v1_account_path(accounts(:checking)), params: {
      account: { name: nil }
    }, as: :json
    assert_response :unprocessable_entity

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")

    accounts(:checking).reload
    assert_equal original_name, accounts(:checking).name
  end

  test "should not update account created by another user" do
    patch api_v1_account_path(accounts(:other_user_account)), params: {
      account: { name: "Hacked Account" }
    }, as: :json
    assert_response :not_found
  end

  test "should not update account to have duplicate name for same owner" do
    original_name = accounts(:savings).name

    patch api_v1_account_path(accounts(:savings)), params: {
      account: { name: accounts(:checking).name }
    }, as: :json
    assert_response :unprocessable_entity

    accounts(:savings).reload
    assert_equal original_name, accounts(:savings).name
  end

  # Destroy tests
  test "should destroy account" do
    assert_difference("Account.count", -1) do
      delete api_v1_account_path(accounts(:checking)), as: :json
      assert_response :ok
    end
  end

  test "should destroy account within owner scope" do
    assert_difference("Account.count", -1) do
      delete api_v1_owner_account_path(owners(:one), accounts(:checking)), as: :json
      assert_response :ok
    end
  end

  test "should not destroy account created by another user" do
    assert_no_difference("Account.count") do
      delete api_v1_account_path(accounts(:other_user_account)), as: :json
      assert_response :not_found
    end
  end

  # Transaction relationship tests
  test "should get sent transactions for account" do
    get sent_transactions_api_v1_account_path(accounts(:checking)), as: :json
    assert_response :success

    transactions = JSON.parse(response.body)
    transaction_ids = transactions.map { |t| t["id"] }

    # Verify it includes transactions sent from this account
    transactions.each do |transaction|
      assert_equal accounts(:checking).id, transaction["from_account_id"]
    end
  end

  test "should get received transactions for account" do
    get received_transactions_api_v1_account_path(accounts(:savings)), as: :json
    assert_response :success

    transactions = JSON.parse(response.body)

    # Verify it includes transactions received by this account
    transactions.each do |transaction|
      assert_equal accounts(:savings).id, transaction["to_account_id"]
    end
  end

  test "should get all transactions for account" do
    get transactions_api_v1_account_path(accounts(:checking)), as: :json
    assert_response :success

    transactions = JSON.parse(response.body)

    # Verify transactions involve this account either as sender or receiver
    transactions.each do |transaction|
      assert(
        transaction["from_account_id"] == accounts(:checking).id ||
        transaction["to_account_id"] == accounts(:checking).id,
        "Transaction should involve the specified account"
      )
    end
  end
end

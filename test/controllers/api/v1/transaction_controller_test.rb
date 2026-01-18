require "test_helper"

class Api::V1::TransactionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post api_v1_login_path, params: { email_address: users(:one).email_address, password: "password" }, as: :json
    assert_response :success, "failed to log into user"
  end

  # Index tests
  test "should get all transactions for current user" do
    get api_v1_transactions_path, as: :json
    assert_response :success

    transactions = JSON.parse(response.body)
    transaction_ids = transactions.map { |t| t["id"] }

    # Should include user one's transactions
    assert_includes transaction_ids, transactions(:internal_transfer).id
    assert_includes transaction_ids, transactions(:expense).id
    assert_includes transaction_ids, transactions(:income).id

    # Should not include other user's transactions
    assert_not_includes transaction_ids, transactions(:other_user_transaction).id
  end

  # Show tests
  test "should get transaction" do
    get api_v1_transaction_path(transactions(:internal_transfer)), as: :json
    assert_response :success

    transaction = JSON.parse(response.body)
    assert_equal transactions(:internal_transfer).id, transaction["id"]
    assert_equal transactions(:internal_transfer).name, transaction["name"]
    assert_equal transactions(:internal_transfer).amount.to_s, transaction["amount"]
  end

  test "should not get transaction created by another user" do
    get api_v1_transaction_path(transactions(:other_user_transaction)), as: :json
    assert_response :not_found
  end

  # Create tests
  test "should create internal transaction" do
    initial_checking_balance = accounts(:checking).balance
    initial_savings_balance = accounts(:savings).balance
    amount = 100.00

    assert_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "New Internal Transfer",
          amount: amount,
          from_account_id: accounts(:checking).id,
          to_account_id: accounts(:savings).id
        }
      }, as: :json
      assert_response :created
    end

    transaction = JSON.parse(response.body)
    assert_equal "New Internal Transfer", transaction["name"]
    assert_equal amount.to_s, transaction["amount"]
    assert_equal accounts(:checking).id, transaction["from_account_id"]
    assert_equal accounts(:savings).id, transaction["to_account_id"]
    assert_equal Date.today.to_s, transaction["transaction_date"]
    assert_equal false, transaction["external"]

    # Verify balances were updated
    accounts(:checking).reload
    accounts(:savings).reload
    assert_equal (initial_checking_balance - amount).to_f, accounts(:checking).balance.to_f
    assert_equal (initial_savings_balance + amount).to_f, accounts(:savings).balance.to_f
  end

  test "should create expense transaction" do
    initial_balance = accounts(:checking).balance
    amount = 50.00

    assert_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Grocery Shopping",
          amount: amount,
          from_account_id: accounts(:checking).id,
          to_account_id: nil
        }
      }, as: :json
      assert_response :created
    end

    transaction = JSON.parse(response.body)
    assert_equal "Grocery Shopping", transaction["name"]
    assert_equal amount.to_s, transaction["amount"]
    assert_equal accounts(:checking).id, transaction["from_account_id"]
    assert_nil transaction["to_account_id"]
    assert_equal true, transaction["external"]

    # Verify balance was updated
    accounts(:checking).reload
    assert_equal (initial_balance - amount).to_f, accounts(:checking).balance.to_f
  end

  test "should create income transaction" do
    initial_balance = accounts(:checking).balance
    amount = 1000.00

    assert_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Salary",
          amount: amount,
          from_account_id: nil,
          to_account_id: accounts(:checking).id
        }
      }, as: :json
      assert_response :created
    end

    transaction = JSON.parse(response.body)
    assert_equal "Salary", transaction["name"]
    assert_equal amount.to_s, transaction["amount"]
    assert_nil transaction["from_account_id"]
    assert_equal accounts(:checking).id, transaction["to_account_id"]
    assert_equal true, transaction["external"]

    # Verify balance was updated
    accounts(:checking).reload
    assert_equal (initial_balance + amount).to_f, accounts(:checking).balance.to_f
  end

  test "should create external transaction between different owners" do
    initial_checking_balance = accounts(:checking).balance
    initial_other_owner_balance = accounts(:other_owner_account).balance
    amount = 75.00

    assert_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Transfer to Other Owner",
          amount: amount,
          from_account_id: accounts(:checking).id,
          to_account_id: accounts(:other_owner_account).id
        }
      }, as: :json
      assert_response :created
    end

    transaction = JSON.parse(response.body)
    assert_equal true, transaction["external"]

    # Verify balances were updated
    accounts(:checking).reload
    accounts(:other_owner_account).reload
    assert_equal (initial_checking_balance - amount).to_f, accounts(:checking).balance.to_f
    assert_equal (initial_other_owner_balance + amount).to_f, accounts(:other_owner_account).balance.to_f
  end

  test "should create transaction with specific date" do
    transaction_date = 5.days.ago.to_date

    assert_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Past Transaction",
          amount: 25.00,
          from_account_id: accounts(:checking).id,
          to_account_id: accounts(:savings).id,
          transaction_date: transaction_date
        }
      }, as: :json
      assert_response :created
    end

    transaction = JSON.parse(response.body)
    assert_equal transaction_date.to_s, transaction["transaction_date"]
  end

  test "should not create transaction with invalid params" do
    assert_no_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Invalid Transaction",
          amount: nil,
          from_account_id: accounts(:checking).id,
          to_account_id: accounts(:savings).id
        }
      }, as: :json
      assert_response :unprocessable_entity
    end

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")
  end

  test "should not create transaction with negative amount" do
    assert_no_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Negative Transaction",
          amount: -100.00,
          from_account_id: accounts(:checking).id,
          to_account_id: accounts(:savings).id
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should not create transaction with zero amount" do
    assert_no_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Zero Transaction",
          amount: 0,
          from_account_id: accounts(:checking).id,
          to_account_id: accounts(:savings).id
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should not create transaction with same from and to account" do
    assert_no_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Self Transfer",
          amount: 100.00,
          from_account_id: accounts(:checking).id,
          to_account_id: accounts(:checking).id
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should not create transaction with both accounts blank" do
    assert_no_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "No Accounts",
          amount: 100.00,
          from_account_id: nil,
          to_account_id: nil
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should not create transaction with future date" do
    future_date = 1.day.from_now.to_date

    assert_no_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Future Transaction",
          amount: 100.00,
          from_account_id: accounts(:checking).id,
          to_account_id: accounts(:savings).id,
          transaction_date: future_date
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should not create transaction involving only other user's accounts" do
    assert_no_difference("Transaction.count") do
      post api_v1_transactions_path, params: {
        transaction: {
          name: "Unauthorized Transaction",
          amount: 100.00,
          from_account_id: accounts(:checking).id,
          to_account_id: accounts(:other_user_account).id
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  # Update tests
  test "should update transaction amount" do
    transaction = transactions(:internal_transfer)
    original_checking_balance = accounts(:checking).balance
    original_savings_balance = accounts(:savings).balance
    original_amount = transaction.amount
    new_amount = 150.00

    patch api_v1_transaction_path(transaction), params: {
      transaction: { amount: new_amount }
    }, as: :json
    assert_response :success

    # Verify transaction was updated
    transaction.reload
    assert_equal new_amount, transaction.amount.to_f

    # Verify balances reflect the new amount
    # (old transaction undone, new transaction applied)
    accounts(:checking).reload
    accounts(:savings).reload

    expected_checking = original_checking_balance + original_amount - new_amount
    expected_savings = original_savings_balance - original_amount + new_amount

    assert_equal expected_checking.to_f, accounts(:checking).balance.to_f
    assert_equal expected_savings.to_f, accounts(:savings).balance.to_f
  end

  test "should update transaction name" do
    patch api_v1_transaction_path(transactions(:internal_transfer)), params: {
      transaction: { name: "Updated Transaction Name" }
    }, as: :json
    assert_response :success

    transactions(:internal_transfer).reload
    assert_equal "Updated Transaction Name", transactions(:internal_transfer).name
  end

  test "should update transaction date" do
    new_date = 3.days.ago.to_date

    patch api_v1_transaction_path(transactions(:internal_transfer)), params: {
      transaction: { transaction_date: new_date }
    }, as: :json
    assert_response :success

    transactions(:internal_transfer).reload
    assert_equal new_date, transactions(:internal_transfer).transaction_date
  end

  test "should not update transaction created by another user" do
    patch api_v1_transaction_path(transactions(:other_user_transaction)), params: {
      transaction: { name: "Hacked Transaction" }
    }, as: :json
    assert_response :not_found
  end

  test "should not update transaction with invalid amount" do
    original_amount = transactions(:internal_transfer).amount

    patch api_v1_transaction_path(transactions(:internal_transfer)), params: {
      transaction: { amount: -50.00 }
    }, as: :json
    assert_response :unprocessable_entity

    transactions(:internal_transfer).reload
    assert_equal original_amount, transactions(:internal_transfer).amount
  end

  # Destroy tests
  test "should destroy transaction and revert balances" do
    transaction = transactions(:internal_transfer)
    initial_checking_balance = accounts(:checking).balance
    initial_savings_balance = accounts(:savings).balance
    amount = transaction.amount

    assert_difference("Transaction.count", -1) do
      delete api_v1_transaction_path(transaction), as: :json
      assert_response :ok
    end

    # Verify balances were reverted
    accounts(:checking).reload
    accounts(:savings).reload

    expected_checking = initial_checking_balance + amount
    expected_savings = initial_savings_balance - amount

    assert_equal expected_checking.to_f, accounts(:checking).balance.to_f
    assert_equal expected_savings.to_f, accounts(:savings).balance.to_f
  end

  test "should destroy expense transaction and revert balance" do
    transaction = transactions(:expense)
    initial_balance = accounts(:checking).balance
    amount = transaction.amount

    assert_difference("Transaction.count", -1) do
      delete api_v1_transaction_path(transaction), as: :json
      assert_response :ok
    end

    # Verify balance was reverted
    accounts(:checking).reload
    assert_equal (initial_balance + amount).to_f, accounts(:checking).balance.to_f
  end

  test "should destroy income transaction and revert balance" do
    transaction = transactions(:income)
    initial_balance = accounts(:checking).balance
    amount = transaction.amount

    assert_difference("Transaction.count", -1) do
      delete api_v1_transaction_path(transaction), as: :json
      assert_response :ok
    end

    # Verify balance was reverted
    accounts(:checking).reload
    assert_equal (initial_balance - amount).to_f, accounts(:checking).balance.to_f
  end

  test "should not destroy transaction created by another user" do
    assert_no_difference("Transaction.count") do
      delete api_v1_transaction_path(transactions(:other_user_transaction)), as: :json
      assert_response :not_found
    end
  end
end

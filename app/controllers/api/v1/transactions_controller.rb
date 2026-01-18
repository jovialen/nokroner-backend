class Api::V1::TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[ show update destroy ]

  # @summary List all transactions
  # @auth [bearer, api_key_cookie]
  # @response Success(200) [Array<!Transaction>]
  def index
    render json: Transaction.created_by_user
  end

  # @summary View a transaction
  # @auth [bearer, api_key_cookie]
  #
  # @parameters id(path) [Integer] Used for identifying the transaction.
  # @response Success(200) [!Transaction]
  def show
    render json: @transaction
  end

  # @summary Create a new transaction
  # @auth [bearer, api_key_cookie]
  #
  # @request_body Transaction to create [!Hash{ name: String, amount: Float, from_account_id: Integer, to_account_id: Integer, transaction_date: Date }]
  # @request_body_example Example transaction [{ "name": "Transaction", "amount": 10, "from_account_id": 1, "to_account_id": 2 }]
  # @response Success(200) [!Transaction]
  # @response Invalid input(422) [!Hash{ errors: Array<String> }]
  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.created_by = Current.user
    @transaction.transaction_date = Date.today unless @transaction.transaction_date

    if @transaction.save
      render json: @transaction, status: :created
    else
      render json: { errors: @transaction.errors }, status: :unprocessable_entity
    end
  end

  # @summary Update a transaction
  # @auth [bearer, api_key_cookie]
  #
  # @parameters id(path) [Integer] Used for identifying the transaction.
  # @request_body Transaction to create [!Hash{ name: String, amount: Float, from_account_id: Integer, to_account_id: Integer, transaction_date: Date }]
  # @request_body_example Example data [{ transaction: { amount: 5 } }]
  # @response Success(200) [!Transaction]
  # @response Invalid input(422) [!Hash{ errors: Array<String> }]
  def update
    if @transaction.update(transaction_params)
      render json: @transaction
    else
      render json: { errors: @transaction.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # @summary Destroy a transaction
  # @auth [bearer, api_key_cookie]
  #
  # @parameters id(path) [Integer] Used for identifying the transaction.
  # @response Success(200) []
  def destroy
    @transaction.destroy
    head(:ok)
  end

  private

  def set_transaction
    @transaction = Transaction.created_by_user.find(params[:id])
  end

  def transaction_params
    params.expect(transaction: [ :name, :amount, :from_account_id, :to_account_id, :transaction_date ])
  end
end

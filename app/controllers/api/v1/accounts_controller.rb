class Api::V1::AccountsController < ApplicationController
  before_action :set_owner, only: %i[ index create ]
  before_action :set_account, only: %i[ show update destroy sent received transactions ]

  # @summary List accounts
  # @auth [bearer, api_key_cookie]
  # @response Success(200) [Array<!Hash{ id: Integer, name: String, account_number: String, balance: String, owner_id: Integer, created_at: String, updated_at: String }>]
  def index
    render json: @owner ? @owner.accounts : Account.created_by_user
  end

  # @summary Show account
  # @auth [bearer, api_key_cookie]
  #
  # @parameter id(path) [Integer] Used for identifying the account.
  # @response Success(200) [!Hash{ id: Integer, name: String, account_number: String, balance: String, owner_id: Integer, created_at: String, updated_at: String }]
  def show
    render json: @account
  end

  # @summary Create account
  # @auth [bearer, api_key_cookie]
  #
  # @request_body The account to be created. [!Hash{ name: String, account_number: String, balance: Float, owner_id: Integer }]
  # @request_body_example Example account [{ "name": "My account", "account_number": "1234 56 78900", "balance": 0, "owner_id": 1 }]
  # @response Success(200) [!Hash{ id: Integer, name: String, account_number: String, balance: String, owner_id: Integer, created_at: String, updated_at: String }]
  # @response Invalid input(422) [!Hash{ errors: Array<String> }]
  def create
    @account = @owner ? @owner.accounts.build(account_params) : Account.new(account_params)

    if @account.save
      render json: @account, status: :created
    else
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # @summary Update account
  # @auth [bearer, api_key_cookie]
  #
  # @parameter id(path) [Integer] Used for identifying the account.
  # @request_body The account to be created. [!Hash{ name: String, account_number: String, balance: Float, owner_id: Integer }]
  # @request_body_example Example account [{ "name": "New name" }]
  # @response Success(200) [!Hash{ id: Integer, name: String, account_number: String, balance: String, owner_id: Integer, created_at: String, updated_at: String }]
  # @response Invalid input(422) [!Hash{ errors: Array<String> }]
  def update
    if @account.update(account_params)
      render json: @account
    else
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # @summary Destroy account
  # @auth [bearer, api_key_cookie]
  #
  # @parameter id(path) [Integer] Used for identifying the account.
  # @response Success(200) []
  def destroy
    @account.destroy
    head(:ok)
  end

  # @summary Transactions from account
  # @response Success(200) [Array<!Transaction>]
  def sent
    render json: @account.sent_transactions
  end

  # @summary Transactions to account
  # @response Success(200) [Array<!Transaction>]
  def received
    render json: @account.received_transactions
  end

  # @summary Account transactions
  # @response Success(200) [Array<!Transaction>]
  def transactions
    render json: @account.transactions
  end

  private

  def set_owner
    @owner = Owner.created_by_user.find(params[:owner_id]) if params[:owner_id]
  end

  def set_account
    set_owner
    accounts = (@owner ? @owner.accounts : Account.created_by_user)
    @account = accounts.find(params[:id])
  end

  def account_params
    params.expect(account: [ :name, :account_number, :balance, :owner_id ])
  end
end

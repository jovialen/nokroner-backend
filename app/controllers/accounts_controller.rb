class AccountsController < ApplicationController
  before_action :set_accounts
  before_action :set_account, only: %i[ show update destroy ]

  # GET /accounts
  def index
    render json: @accounts
  end

  # GET /accounts/1
  def show
    render json: @account
  end

  # POST /accounts
  def create
    @account = Account.create!(account_params)
    render json: @account, status: :created, location: @account
  end

  # PATCH/PUT /accounts/1
  def update
    @account.update!(account_params)
    render json: @account
  end

  # DELETE /accounts/1
  def destroy
    @account.destroy!
  end

  private

  # Find the accounts we are working with
  def set_accounts
    @accounts = Account.where(owner: Current.user.all_groups)
  end

  # Find the specific account we are working on
  def set_account
    @account = @accounts.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def account_params
    params.expect(account: [ :name, :owner_id ])
  end
end

class AccountsController < ApplicationController
  before_action :set_accounts
  before_action :set_account, only: %i[ show show_history update destroy ]

  # GET /accounts
  def index
    render json: @accounts
  end

  # GET /accounts/1
  def show
    render json: @account
  end

  # GET /accounts/1/history
  def show_history
    render json: @account.balance_snapshots
  end

  # POST /accounts
  def create
    ApplicationRecord.transaction do
      @account = Account.create!(account_params)
      AccountBalanceService.update_balance(@account, params[:balance]) if params[:balance]
      render json: @account, status: :created, location: @account
    end
  end

  # PATCH/PUT /accounts/1
  def update
    ApplicationRecord.transaction do
      @account.update!(account_params)
      AccountBalanceService.update_balance(@account, params[:balance]) if params[:balance]
      render json: @account
    end
  end

  # DELETE /accounts/1
  def destroy
    @account.destroy!
    TransactionCleanupJob.perform_later
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
    params.permit(:id, :balance, account: [ :name, :owner_id ])
      .fetch(:account, {})
  end
end

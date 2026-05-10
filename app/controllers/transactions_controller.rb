class TransactionsController < ApplicationController
  before_action :set_transactions
  before_action :set_transaction, only: %i[ show update destroy ]

  # GET /transactions
  def index
    render json: @transactions
  end

  # GET /transactions/1
  def show
    render json: @transaction
  end

  # POST /transactions
  def create
    @transaction = Transaction.create!(transaction_params)
    TransactionService.new(@transaction).perform
    render json: @transaction, status: :created, location: @transaction
  end

  # PATCH/PUT /transactions/1
  def update
    service = TransactionService.new(@transaction)

    ApplicationRecord.transaction do
      service.undo
      @transaction.update!(transaction_params)
      service.perform
    end

    render json: @transaction
  end

  # DELETE /transactions/1
  def destroy
    ApplicationRecord.transaction do
      TransactionService.new(@transaction).undo
      @transaction.destroy!
    end
  end

  private

  def set_transactions
   @transactions = Transaction
    .joins("INNER JOIN accounts from_accounts ON from_accounts.id = transactions.from_id
            INNER JOIN groups from_groups ON from_groups.id = from_accounts.owner_id
            INNER JOIN accounts to_accounts ON to_accounts.id = transactions.to_id
            INNER JOIN groups to_groups ON to_groups.id = to_accounts.owner_id")
    .where("from_groups.created_by_id = :user_id OR to_groups.created_by_id = :user_id",
        user_id: Current.user.id)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_transaction
    @transaction = @transactions.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def transaction_params
    params.expect(transaction: [ :name, :amount, :from_id, :to_id, :date ])
  end
end

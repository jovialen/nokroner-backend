class TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[ show update destroy ]

  # GET /transactions
  def index
    @transactions = Transaction.created_by_user

    render json: @transactions
  end

  # GET /transactions/1
  def show
    render json: @transaction
  end

  # POST /transactions
  def create
    @transaction = Transaction.new(transaction_params)
    @transaction.creator = Current.user

    if @transaction.save
      render json: @transaction, status: :created, location: @transaction
    else
      render json: @transaction.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /transactions/1
  def update
    if @transaction.update(transaction_params)
      render json: @transaction
    else
      render json: @transaction.errors, status: :unprocessable_content
    end
  end

  # DELETE /transactions/1
  def destroy
    @transaction.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction
      @transaction = Transaction.created_by_user.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def transaction_params
      params.expect(transaction: [ :name, :amount, :from_account_id, :to_account_id ])
    end
end

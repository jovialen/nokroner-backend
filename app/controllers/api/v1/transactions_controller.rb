class Api::V1::TransactionsController < ApplicationController
  before_action :set_transaction, only: %i[ show update destroy ]

  def index
    render json: Transaction.created_by_user
  end

  def show
    render json: @transaction
  end

  def create
    @transaction = Current.user.transactions.build(transaction_params)

    if @transaction.save
      render json: @transaction, status: :created
    else
      render json: { errors: @transaction.errors }, status: :unprocessable_entity
    end
  end

  def update
    @transaction.update(transaction_params)
  end

  def destroy
    @transaction.destroy
  end

  private

  def set_transaction
    @transaction = Transaction.created_by_user.find(params[:id])
  end

  def transaction_params
    params.expect(transaction: [ :name, :amount, :from_account_id, :to_account_id ])
  end
end

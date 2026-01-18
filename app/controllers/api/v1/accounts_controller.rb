class Api::V1::AccountsController < ApplicationController
  before_action :set_owner, only: %i[ index create ]
  before_action :set_account, only: %i[ show update destroy ]

  def index
    render json: @owner ? @owner.accounts : Account.created_by_user
  end

  def show
    render json: @account
  end

  def create
    @account = @owner ? @owner.accounts.build(account_params) : Account.new(account_params)

    if @account.save
      render json: @account, status: :created
    else
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @account.update(account_params)
      render json: @account
    else
      render json: { errors: @account.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @account.destroy
    head(:ok)
  end

  private

  def set_owner
    @owner = Owner.created_by_user.find(params[:owner_id]) if params[:owner_id]
  end

  def set_account
    set_owner
    accounts = @owner ? @owner.accounts : Owner.created_by_user
    @account = accounts.find(params[:id])
  end

  def account_params
    # TODO: Important! Validate that the owner_id belongs to an owner created
    #       by the current user
    params.expect(account: [ :name, :account_number, :balance, :owner_id ])
  end
end

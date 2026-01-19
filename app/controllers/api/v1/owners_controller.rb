class Api::V1::OwnersController < ApplicationController
  before_action :set_owner, only: %i[ show update destroy history ]

  # @summary List owners.
  # @auth [bearer, api_key_cookie]
  # List all owners created by the currently logged-in user
  #
  # @response Success(200) [Array<!Owner>]
  def index
    render json: Owner.created_by_user
  end

  # @summary Show an owner.
  # @auth [bearer, api_key_cookie]
  # @parameters id(path) Used for identifying the owner.
  # Show the requested owner.
  #
  # @response Success(200) [!Owner]
  def show
    render json: @owner
  end

  # @summary Create a new owner.
  # @auth [bearer, api_key_cookie]
  # Create a new owner and return it. The created by field will be
  # automatically filled in as the currently logged-in user.
  #
  # @request_body Owner to create. [!Owner]
  # @response Success(200) [!Owner]
  # @response Invalid input(422) [!Hash{ errors: Array<String> }]
  def create
    @owner = Owner.new(owner_params)
    @owner.created_by = Current.user

    if @owner.save
      render json: @owner, status: :created, location: api_v1_owner_path(@owner)
    else
      render json: { errors: @owner.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # @summary Update an owner.
  # @auth [bearer, api_key_cookie]
  # @parameters id(path) Used for identifying the owner.
  # Update the given owner with the given data. The created by field cannot
  # be updated.
  #
  # @request_body Data to update. [!Owner]
  # @response Success(200) [!Owner]
  # @response Invalid input(422) [!Hash{ errors: Array<String> }]
  def update
    if @owner.update(owner_params)
      render json: @owner
    else
      render json: { errors: @owner.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # @summary Delete an owner.
  # @auth [bearer, api_key_cookie]
  # @parameters id(path) Used for identifying the owner.
  # Delete the given owner and all the accounts it owns. Any transactions
  # connected to any of these accounts will have the attribute the owner
  # account is used in set to null.
  #
  # @response Success(200) []
  def destroy
    unless Current.user.owner == @owner
      @owner.destroy
      head(:ok)
    else
      render json: { error: "cannot delete user owner. delete user instead" }, status: :bad_request
    end
  end

  # @summary Balance history of the owner
  # Calculate the sum balance of all the user accounts during a user defined
  # period.
  #
  # @parameter id(path) [Integer] Used for identifying the owner
  # @parameter start_date(query) [Date] Where to start calculating history from
  # @parameter end_date(query) [Date] Where to end calculating history from
  # @parameter period(query) [String] default: (quarter) enum: (week,month,quarter,year)
  # @response Success(200) [Array<!Hash{ period_start: Date, period_end: Date, income: String, expenses: String, net_change: String, initial_balance: String, end_balance: String }>]
  def history
    start_date = params[:start_date].to_date if params[:start_date]
    end_date   = params[:end_date].to_date   if params[:end_date]
    period     = params.fetch(:period, "quarter").to_sym

    render json: BalanceBreakdownQuery.new(accounts: @owner.accounts)
                                      .start_date(start_date)
                                      .end_date(end_date)
                                      .grouped_by(period)
                                      .execute
  end

  private

  def set_owner
    @owner = Owner.created_by_user.find(params[:id])
  end

  def owner_params
    params.expect(owner: [ :name ])
  end
end

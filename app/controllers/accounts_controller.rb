class AccountsController < ApplicationController
  before_action :set_account, only: %i[ show update destroy money_flow ]

  # GET /accounts
  def index
    @accounts = Account.created_by_user

    render json: @accounts
  end

  # GET /accounts/1
  def show
    render json: @account.as_json(
      methods: [ :recent_expenses, :recent_income, :previous_expenses, :previous_income, :balance_last_month ]
    )
  end
  
  PERIODS = {
    month: "month",
    week: "week"
  }

  # GET/accounts/1/money_flow
  def money_flow
    year = params.fetch(:year, Date.current.year).to_i
    period = params.fetch(:period, "month").to_sym

    trunc = PERIODS.fetch(period) { raise ArgumentError, "Invalid period #{period}" }

    incoming = Transaction
      .where(to_account_id: :id)
      .year(year)
      .group("DATE_TRUNC('#{trunc}', transaction_date)")
      .sum(:amount)
      .transform_keys { |date| date.to_date }
      
    outgoing = Transaction
      .where(from_account_id: :id)
      .year(year)
      .group("DATE_TRUNC('#{trunc}', transaction_date)")
      .sum(:amount)
      .transform_keys { |date| date.to_date }

    all_periodes = case period
    when :month
      (1..12).map do |month| Date.new(year, month, 1) end
    when :week
      (1..Date.new(year).end_of_year.cweek).map do |week| Date.commercial(year, week, 1) end
    end

    summary = all_periodes.map do |p|
      {
        period: p,
        income: incoming[p] || 0,
        expenses: outgoing[p] || 0,
        net: (incoming[p] || 0) - (outgoing[p] || 0)
      }
    end

    render json: {
      account_id: :id,
      year: year,
      period: period,
      total: {
        income: incoming.values.sum,
        expenses: outgoing.values.sum,
        net: incoming.values.sum - outgoing.values.sum
      },
      incoming: incoming,
      outgoing: outgoing,
      all: summary
    }
  end

  # POST /accounts
  def create
    @account = Account.new(account_params)
    @account.creator = Current.user

    if @account.save
      render json: @account, status: :created, location: @account
    else
      render json: @account.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /accounts/1
  def update
    if @account.update(account_params)
      render json: @account
    else
      render json: @account.errors, status: :unprocessable_content
    end
  end

  # DELETE /accounts/1
  def destroy
    @account.destroy!
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_account
    @account = Account.created_by_user.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def account_params
    params.expect(account: [ :account_number, :name, :balance, :interest, :owner_id ])
  end
end

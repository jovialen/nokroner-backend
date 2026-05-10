class SubscriptionsController < ApplicationController
  before_action :set_subscriptions
  before_action :set_subscription, only: %i[ show show_transactions update destroy ]

  # GET /subscriptions
  def index
    render json: @subscriptions
  end

  # GET /subscriptions/1
  def show
    render json: @subscription
  end

  # GET /subscriptions/1/transactions
  def show_transactions
    render json: @subscription.transactions
  end

  # POST /subscriptions
  def create
    @subscription = Subscription.create!(subscription_params)
    render json: @subscription, status: :created, location: @subscription
  end

  # PATCH/PUT /subscriptions/1
  def update
    @subscription.update!(subscription_params)
    render json: @subscription
  end

  # DELETE /subscriptions/1
  def destroy
    @subscription.destroy!
  end

  private

  def set_subscriptions
    # Since both from and to must always exist, just checking one is fine
    @subscriptions = Subscription.joins(from: { owner: :created_by })
      .where(owner: { created_by_id: Current.user.id })
  end

  def set_subscription
    @subscription = Subscription.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def subscription_params
    params.expect(subscription: [ :name, :from_id, :to_id, :amount, :cron, :autorun ])
  end
end

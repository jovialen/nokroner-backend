class OwnersController < ApplicationController
  before_action :set_owner, only: %i[ show update destroy ]

  # GET /owners
  def index
    @owners = Owner.created_by_user
      .left_joins(:accounts)
      .select(
        "owners.*,
         COALESCE(SUM(accounts.balance), 0) AS net_worth"
      )
      .group("owners.id")

    render json: @owners.as_json(
      methods: :net_worth
    )
  end

  # GET /owners/1
  def show
    render json: @owner.as_json(
      methods: [ :net_worth, :net_worth_last_month, :recent_income, :recent_expenses, :previous_income, :previous_expenses ]
    )
  end

  # POST /owners
  def create
    @owner = Owner.new(owner_params)
    @owner.creator = Current.user
    @owner.is_user = false

    if @owner.save
      render json: @owner, status: :created, location: @owner
    else
      render json: @owner.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /owners/1
  def update
    if @owner.update(owner_params)
      render json: @owner
    else
      render json: @owner.errors, status: :unprocessable_content
    end
  end

  # DELETE /owners/1
  def destroy
    @owner.destroy!
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_owner
    @owner = Owner.created_by_user.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def owner_params
    params.expect(owner: [ :name, :net_worth ])
  end
end

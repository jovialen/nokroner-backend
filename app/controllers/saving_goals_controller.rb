class SavingGoalsController < ApplicationController
  before_action :set_saving_goal, only: %i[ show update destroy ]

  # GET /saving_goals
  def index
    @saving_goals = SavingGoal.created_by_user

    render json: @saving_goals.as_json(
      methods: [ :saved, :ready ]
    )
  end

  # GET /saving_goals/1
  def show
    render json: @saving_goal.as_json(
      methods: [ :saved, :ready ]
    )
  end

  # POST /saving_goals
  def create
    @saving_goal = SavingGoal.new(saving_goal_params)
    @saving_goal.user = Current.user

    if @saving_goal.save
      render json: @saving_goal, status: :created, location: @saving_goal
    else
      render json: @saving_goal.errors, status: :unprocessable_content
    end
  end

  # PATCH/PUT /saving_goals/1
  def update
    if @saving_goal.update(saving_goal_params)
      render json: @saving_goal
    else
      render json: @saving_goal.errors, status: :unprocessable_content
    end
  end

  # DELETE /saving_goals/1
  def destroy
    @saving_goal.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_saving_goal
      @saving_goal = SavingGoal.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def saving_goal_params
      params.expect(saving_goal: [ :name, :amount, :realized, :archived ])
    end
end

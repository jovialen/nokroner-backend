class Api::V1::SavingGoalsController < ApplicationController
  before_action :set_saving_goal, only: %i[ show update destroy ]

  # @summary List all saving goals
  # @auth [bearer, api_key_cookie]
  # @response Success(200) [Array<!SavingGoal>]
  def index
    @saving_goals = SavingGoal.created_by_user.order(:target_date, :updated_at)
    render json: @saving_goals.as_json(
      methods: [ :saved, :daily_saving ]
    )
  end

  # @summary View saving goal
  # @auth [bearer, api_key_cookie]
  # @parameters id(path) [Integer] Used for identifying the saving goal.
  # @response Success(200) [!SavingGoal]
  def show
    render json: @saving_goal.as_json(
      methods: [ :saved, :daily_saving ]
    )
  end

  # @summary Create saving goal
  # @auth [bearer, api_key_cookie]
  # @request_body Saving goal [!SavingGoal]
  # @response Created(201) [!SavingGoal]
  def create
    @saving_goal = Current.user.saving_goals.build(saving_goal_params)

    if @saving_goal.save
      render json: @saving_goal.as_json(methods: [ :saved, :daily_saving ]), status: :created
    else
      render json: { errors: @saving_goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # @summary Update saving goal
  # @auth [bearer, api_key_cookie]
  # @parameters id(path) [Integer] Used for identifying the saving goal.
  # @request_body Data. [!SavingGoal]
  # @response Success(200) [!SavingGoal]
  def update
    if @saving_goal.update(saving_goal_params)
      render json: @saving_goal.as_json(methods: [ :saved, :daily_saving ])
    else
      render json: { errors: @saving_goal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # @summary Delete saving goal.
  # @auth [bearer, api_key_cookie]
  # @parameters id(path) [Integer] Used for identifying the saving goal.
  # @response Success(200) []
  def destroy
    @saving_goal.destroy
    head(:ok)
  end

  private

  def set_saving_goal
    @saving_goal = SavingGoal.find(params[:id])
  end

  def saving_goal_params
    params.expect(saving_goal: [
      :name,
      :amount,
      :priority,
      :autocomplete,
      :done,
      :archived,
      :target_date
    ])
  end
end

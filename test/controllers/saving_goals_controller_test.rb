require "test_helper"

class SavingGoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @saving_goal = saving_goals(:one)
  end

  test "should get index" do
    get saving_goals_url, as: :json
    assert_response :success
  end

  test "should create saving_goal" do
    assert_difference("SavingGoal.count") do
      post saving_goals_url, params: { saving_goal: { amount: @saving_goal.amount, name: @saving_goal.name, user_id: @saving_goal.user_id } }, as: :json
    end

    assert_response :created
  end

  test "should show saving_goal" do
    get saving_goal_url(@saving_goal), as: :json
    assert_response :success
  end

  test "should update saving_goal" do
    patch saving_goal_url(@saving_goal), params: { saving_goal: { amount: @saving_goal.amount, name: @saving_goal.name, user_id: @saving_goal.user_id } }, as: :json
    assert_response :success
  end

  test "should destroy saving_goal" do
    assert_difference("SavingGoal.count", -1) do
      delete saving_goal_url(@saving_goal), as: :json
    end

    assert_response :no_content
  end
end

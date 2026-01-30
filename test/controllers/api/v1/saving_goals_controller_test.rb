require "test_helper"

class Api::V1::SavingGoalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    post api_v1_login_path, params: { email_address: users(:one).email_address, password: "password" }, as: :json
    assert_response :success, "failed to log into user"
  end

  # ========================================
  # Index Tests
  # ========================================

  test "should get index" do
    get api_v1_saving_goals_path, as: :json
    assert_response :success
  end

  test "should return all saving goals for current user" do
    get api_v1_saving_goals_path, as: :json
    assert_response :success

    goals = JSON.parse(response.body)
    goal_ids = goals.map { |g| g["id"] }

    # Should include user one's goals
    assert_includes goal_ids, saving_goals(:high_priority_incomplete).id
    assert_includes goal_ids, saving_goals(:high_priority_complete).id
    assert_includes goal_ids, saving_goals(:medium_priority_incomplete).id

    # Should not include other user's goals
    assert_not_includes goal_ids, saving_goals(:other_user_goal).id
  end

  test "should return goals ordered by target date and updated_at" do
    get api_v1_saving_goals_path, as: :json
    assert_response :success

    goals = JSON.parse(response.body)

    # Goals should be ordered by target_date first, then updated_at
    # Verify that goals with earlier target dates come first
    target_dates = goals.map { |g| g["target_date"] }.compact
    assert_equal target_dates, target_dates.sort
  end

  test "should include saved and daily_saving methods in response" do
    get api_v1_saving_goals_path, as: :json
    assert_response :success

    goals = JSON.parse(response.body)
    first_goal = goals.first

    assert first_goal.key?("saved"), "Response should include 'saved' method"
    assert first_goal.key?("daily_saving"), "Response should include 'daily_saving' method"
  end

  test "should not get goals when not logged in" do
    delete api_v1_logout_path, as: :json

    get api_v1_saving_goals_path, as: :json
    assert_response :unauthorized
  end

  # ========================================
  # Show Tests
  # ========================================

  test "should show saving goal" do
    get api_v1_saving_goal_path(saving_goals(:high_priority_incomplete)), as: :json
    assert_response :success

    goal = JSON.parse(response.body)
    assert_equal saving_goals(:high_priority_incomplete).id, goal["id"]
    assert_equal saving_goals(:high_priority_incomplete).name, goal["name"]
    assert_equal saving_goals(:high_priority_incomplete).amount.to_s, goal["amount"]
  end

  test "should include saved and daily_saving in show response" do
    get api_v1_saving_goal_path(saving_goals(:high_priority_incomplete)), as: :json
    assert_response :success

    goal = JSON.parse(response.body)
    assert goal.key?("saved")
    assert goal.key?("daily_saving")
  end

  test "should show goal belonging to current user" do
    get api_v1_saving_goal_path(saving_goals(:high_priority_incomplete)), as: :json
    assert_response :success
  end

  test "should not show goal belonging to another user" do
    get api_v1_saving_goal_path(saving_goals(:other_user_goal)), as: :json
    assert_response :not_found
  end

  test "should not show goal when not logged in" do
    delete api_v1_logout_path, as: :json

    get api_v1_saving_goal_path(saving_goals(:high_priority_incomplete)), as: :json
    assert_response :unauthorized
  end

  # ========================================
  # Create Tests
  # ========================================

  test "should create saving goal" do
    assert_difference("SavingGoal.count") do
      post api_v1_saving_goals_path, params: {
        saving_goal: {
          name: "New Saving Goal",
          amount: 500.00,
          priority: 5,
          autocomplete: true,
          done: false,
          archived: false,
          target_date: 60.days.from_now.to_date
        }
      }, as: :json
      assert_response :created
    end

    goal = JSON.parse(response.body)
    assert_equal "New Saving Goal", goal["name"]
    assert_equal "500.0", goal["amount"]
    assert_equal 5, goal["priority"]
    assert_equal true, goal["autocomplete"]
    assert_equal true, goal["done"]
    assert_equal false, goal["archived"]
  end

  test "should create goal associated with current user" do
    post api_v1_saving_goals_path, params: {
      saving_goal: {
        name: "User Associated Goal",
        amount: 300.00,
        priority: 5
      }
    }, as: :json
    assert_response :created

    goal = SavingGoal.find(JSON.parse(response.body)["id"])
    assert_equal users(:one).id, goal.user_id
  end

  test "should create goal with default values" do
    post api_v1_saving_goals_path, params: {
      saving_goal: {
        name: "Minimal Goal",
        amount: 100.00,
        priority: 5
      }
    }, as: :json
    assert_response :created

    goal = JSON.parse(response.body)
    # Check database defaults are applied
    assert_not_nil goal["created_at"]
    assert_not_nil goal["updated_at"]
  end

  test "should not create goal without name" do
    assert_no_difference("SavingGoal.count") do
      post api_v1_saving_goals_path, params: {
        saving_goal: {
          name: nil,
          amount: 500.00,
          priority: 5
        }
      }, as: :json
      assert_response :unprocessable_entity
    end

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")
    assert_kind_of Array, response_body["errors"]
  end

  test "should not create goal without amount" do
    assert_no_difference("SavingGoal.count") do
      post api_v1_saving_goals_path, params: {
        saving_goal: {
          name: "No Amount Goal",
          amount: nil,
          priority: 5
        }
      }, as: :json
      assert_response :unprocessable_entity
    end

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")
  end

  test "should not create goal with negative amount" do
    assert_no_difference("SavingGoal.count") do
      post api_v1_saving_goals_path, params: {
        saving_goal: {
          name: "Negative Goal",
          amount: -100.00,
          priority: 5
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should not create goal with zero amount" do
    assert_no_difference("SavingGoal.count") do
      post api_v1_saving_goals_path, params: {
        saving_goal: {
          name: "Zero Goal",
          amount: 0,
          priority: 5
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should not create duplicate goal name for same user" do
    assert_no_difference("SavingGoal.count") do
      post api_v1_saving_goals_path, params: {
        saving_goal: {
          name: saving_goals(:high_priority_incomplete).name,
          amount: 100.00,
          priority: 5
        }
      }, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "should autocomplete goal on create if conditions met" do
    post api_v1_saving_goals_path, params: {
      saving_goal: {
        name: "Auto Complete Test",
        amount: 50.00,  # Small amount that should be affordable
        priority: 8,
        autocomplete: true
      }
    }, as: :json
    assert_response :created

    goal = JSON.parse(response.body)
    assert_equal true, goal["done"], "Goal should be auto-completed"
  end

  test "should not autocomplete goal if autocomplete is false" do
    post api_v1_saving_goals_path, params: {
      saving_goal: {
        name: "No Auto Complete",
        amount: 50.00,
        priority: 8,
        autocomplete: false
      }
    }, as: :json
    assert_response :created

    goal = JSON.parse(response.body)
    assert_equal false, goal["done"]
  end

  test "should not create goal when not logged in" do
    delete api_v1_logout_path, as: :json

    assert_no_difference("SavingGoal.count") do
      post api_v1_saving_goals_path, params: {
        saving_goal: {
          name: "Unauthorized Goal",
          amount: 100.00,
          priority: 5
        }
      }, as: :json
      assert_response :unauthorized
    end
  end

  # ========================================
  # Update Tests
  # ========================================

  test "should update saving goal" do
    patch api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), params: {
      saving_goal: { name: "Updated Name" }
    }, as: :json
    assert_response :success

    goal = JSON.parse(response.body)
    assert_equal "Updated Name", goal["name"]

    saving_goals(:medium_priority_incomplete).reload
    assert_equal "Updated Name", saving_goals(:medium_priority_incomplete).name
  end

  test "should update goal amount" do
    patch api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), params: {
      saving_goal: { amount: 400.00 }
    }, as: :json
    assert_response :success

    saving_goals(:medium_priority_incomplete).reload
    assert_equal 400.00, saving_goals(:medium_priority_incomplete).amount.to_f
  end

  test "should update goal priority" do
    patch api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), params: {
      saving_goal: { priority: 3 }
    }, as: :json
    assert_response :success

    saving_goals(:medium_priority_incomplete).reload
    assert_equal 3, saving_goals(:medium_priority_incomplete).priority
  end

  test "should update autocomplete flag" do
    patch api_v1_saving_goal_path(saving_goals(:medium_priority_manual)), params: {
      saving_goal: { autocomplete: true }
    }, as: :json
    assert_response :success

    saving_goals(:medium_priority_manual).reload
    assert saving_goals(:medium_priority_manual).autocomplete
  end

  test "should mark goal as done if sufficient funds" do
    patch api_v1_saving_goal_path(saving_goals(:low_priority_small)), params: {
      saving_goal: { done: true }
    }, as: :json
    assert_response :success

    saving_goals(:low_priority_small).reload
    assert saving_goals(:low_priority_small).done
  end

  test "should not mark goal as done without sufficient funds" do
    original_done = saving_goals(:low_priority_large).done

    patch api_v1_saving_goal_path(saving_goals(:low_priority_large)), params: {
      saving_goal: { done: true }
    }, as: :json
    assert_response :unprocessable_entity

    saving_goals(:low_priority_large).reload
    assert_equal original_done, saving_goals(:low_priority_large).done
  end

  test "should archive goal" do
    patch api_v1_saving_goal_path(saving_goals(:high_priority_complete)), params: {
      saving_goal: { archived: true }
    }, as: :json
    assert_response :success

    saving_goals(:high_priority_complete).reload
    assert saving_goals(:high_priority_complete).archived
  end

  test "should update target date" do
    new_date = 90.days.from_now.to_date

    patch api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), params: {
      saving_goal: { target_date: new_date }
    }, as: :json
    assert_response :success

    saving_goals(:medium_priority_incomplete).reload
    assert_equal new_date, saving_goals(:medium_priority_incomplete).target_date
  end

  test "should not update goal with invalid name" do
    original_name = saving_goals(:medium_priority_incomplete).name

    patch api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), params: {
      saving_goal: { name: nil }
    }, as: :json
    assert_response :unprocessable_entity

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")

    saving_goals(:medium_priority_incomplete).reload
    assert_equal original_name, saving_goals(:medium_priority_incomplete).name
  end

  test "should not update goal with negative amount" do
    original_amount = saving_goals(:medium_priority_incomplete).amount

    patch api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), params: {
      saving_goal: { amount: -100.00 }
    }, as: :json
    assert_response :unprocessable_entity

    saving_goals(:medium_priority_incomplete).reload
    assert_equal original_amount, saving_goals(:medium_priority_incomplete).amount
  end

  test "should not update goal to duplicate name" do
    original_name = saving_goals(:medium_priority_incomplete).name

    patch api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), params: {
      saving_goal: { name: saving_goals(:high_priority_incomplete).name }
    }, as: :json
    assert_response :unprocessable_entity

    saving_goals(:medium_priority_incomplete).reload
    assert_equal original_name, saving_goals(:medium_priority_incomplete).name
  end

  test "should not update another user's goal" do
    patch api_v1_saving_goal_path(saving_goals(:other_user_goal)), params: {
      saving_goal: { name: "Hacked Goal" }
    }, as: :json
    assert_response :not_found
  end

  test "should not update goal when not logged in" do
    delete api_v1_logout_path, as: :json

    patch api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), params: {
      saving_goal: { name: "Unauthorized Update" }
    }, as: :json
    assert_response :unauthorized
  end

  # ========================================
  # Destroy Tests
  # ========================================

  test "should destroy saving goal" do
    assert_difference("SavingGoal.count", -1) do
      delete api_v1_saving_goal_path(saving_goals(:no_target_date)), as: :json
      assert_response :ok
    end
  end

  test "should destroy incomplete goal" do
    assert_difference("SavingGoal.count", -1) do
      delete api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), as: :json
      assert_response :ok
    end
  end

  test "should destroy completed goal" do
    assert_difference("SavingGoal.count", -1) do
      delete api_v1_saving_goal_path(saving_goals(:high_priority_complete)), as: :json
      assert_response :ok
    end
  end

  test "should destroy archived goal" do
    assert_difference("SavingGoal.count", -1) do
      delete api_v1_saving_goal_path(saving_goals(:completed_archived)), as: :json
      assert_response :ok
    end
  end

  test "should not destroy another user's goal" do
    assert_no_difference("SavingGoal.count") do
      delete api_v1_saving_goal_path(saving_goals(:other_user_goal)), as: :json
      assert_response :not_found
    end
  end

  test "should not destroy goal when not logged in" do
    delete api_v1_logout_path, as: :json

    assert_no_difference("SavingGoal.count") do
      delete api_v1_saving_goal_path(saving_goals(:medium_priority_incomplete)), as: :json
      assert_response :unauthorized
    end
  end

  # ========================================
  # Edge Case Tests
  # ========================================

  test "should handle goal with nil target date" do
    get api_v1_saving_goal_path(saving_goals(:no_target_date)), as: :json
    assert_response :success

    goal = JSON.parse(response.body)
    assert_nil goal["target_date"]
    assert_nil goal["daily_saving"]
  end

  test "should handle overdue goal" do
    get api_v1_saving_goal_path(saving_goals(:overdue_goal)), as: :json
    assert_response :success

    goal = JSON.parse(response.body)
    assert goal["target_date"] < Date.today.to_s
    # daily_saving should equal full amount for overdue goals
    assert_equal goal["amount"], goal["daily_saving"].to_s
  end

  test "should return correct saved amount for completed goal" do
    get api_v1_saving_goal_path(saving_goals(:high_priority_complete)), as: :json
    assert_response :success

    goal = JSON.parse(response.body)
    # Completed goals should show saved = amount
    assert_equal goal["amount"], goal["saved"].to_s
  end

  test "should handle multiple operations in sequence" do
    # Create a goal
    post api_v1_saving_goals_path, params: {
      saving_goal: {
        name: "Sequential Test",
        amount: 200.00,
        priority: 15
      }
    }, as: :json
    assert_response :created

    goal_id = JSON.parse(response.body)["id"]

    # Update it
    patch api_v1_saving_goal_path(goal_id), params: {
      saving_goal: { name: "Updated Sequential Test" }
    }, as: :json
    assert_response :success

    # Retrieve it
    get api_v1_saving_goal_path(goal_id), as: :json
    assert_response :success
    assert_equal "Updated Sequential Test", JSON.parse(response.body)["name"]

    # Delete it
    delete api_v1_saving_goal_path(goal_id), as: :json
    assert_response :ok
  end
end

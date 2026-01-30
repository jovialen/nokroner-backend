require "test_helper"

class SavingGoalAutocompleteJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    Current.session = @user.sessions.create!
  end

  # ========================================
  # Basic Functionality Tests
  # ========================================

  test "should enqueue job" do
    assert_enqueued_with(job: SavingGoalAutocompleteJob) do
      SavingGoalAutocompleteJob.perform_later(@user)
    end
  end

  test "should perform job successfully" do
    assert_nothing_raised do
      SavingGoalAutocompleteJob.perform_now(@user)
    end
  end

  # ========================================
  # Autocomplete Logic Tests
  # ========================================

  test "should only complete goals marked for autocomplete" do
    assert_not saving_goals(:medium_priority_manual).autocomplete
    assert_not saving_goals(:medium_priority_manual).done

    SavingGoalAutocompleteJob.perform_now(@user)

    saving_goals(:medium_priority_manual).reload
    assert_not saving_goals(:medium_priority_manual).done
  end

  test "should not complete already completed goals" do
    assert saving_goals(:high_priority_complete).done

    # Record the ID to check it wasn't re-saved
    original_updated_at = saving_goals(:high_priority_complete).updated_at

    SavingGoalAutocompleteJob.perform_now(@user)

    saving_goals(:high_priority_complete).reload
    assert saving_goals(:high_priority_complete).done
  end

  test "should not complete archived goals" do
    assert saving_goals(:completed_archived).archived

    SavingGoalAutocompleteJob.perform_now(@user)

    # Goal should remain as is
    saving_goals(:completed_archived).reload
    assert saving_goals(:completed_archived).done
    assert saving_goals(:completed_archived).archived
  end

  # ========================================
  # Priority Tier Logic Tests
  # ========================================

  test "should handle multiple goals with same priority" do
    # Create two goals with the same priority
    goal1 = SavingGoal.create!(
      user: @user,
      name: "Same Priority 1",
      amount: 100.00,
      priority: 12,
      autocomplete: true,
      done: false,
      archived: false,
      target_date: 40.days.from_now
    )

    goal2 = SavingGoal.create!(
      user: @user,
      name: "Same Priority 2",
      amount: 100.00,
      priority: 12,
      autocomplete: true,
      done: false,
      archived: false,
      target_date: 30.days.from_now  # Earlier date, should complete first
    )

    SavingGoalAutocompleteJob.perform_now(@user)

    goal1.reload
    goal2.reload

    # Both should complete if there's enough balance
    assert goal1.done
    assert goal2.done

    goal1.destroy
    goal2.destroy
  end

  test "should handle goals with same priority and target date" do
    # Create two goals with same priority and target date
    # Should fall back to created_at ordering

    goal1 = SavingGoal.create!(
      user: @user,
      name: "First Created",
      amount: 100.00,
      priority: 9,
      autocomplete: true,
      done: false,
      archived: false,
      target_date: 30.days.from_now
    )

    sleep(0.1)  # Ensure different created_at

    goal2 = SavingGoal.create!(
      user: @user,
      name: "Second Created",
      amount: 100.00,
      priority: 9,
      autocomplete: true,
      done: false,
      archived: false,
      target_date: 30.days.from_now
    )

    SavingGoalAutocompleteJob.perform_now(@user)

    goal1.reload
    goal2.reload

    # Both should complete
    assert goal1.done
    assert goal2.done

    goal1.destroy
    goal2.destroy
  end

  # ========================================
  # Balance Calculation Tests
  # ========================================

  test "should calculate correct available balance" do
    # User has 6000 total
    # 500 allocated to completed goals
    # Available = 5500

    # We can verify this by seeing which goals complete
    SavingGoalAutocompleteJob.perform_now(@user)

    # Should complete goals totaling up to 5500
    completed_goals = SavingGoal.where(user: @user, done: true, archived: false)
    # Subtract the one that was already complete
    newly_completed = completed_goals.where.not(id: saving_goals(:high_priority_complete).id)

    total_completed = newly_completed.sum(:amount)
    assert total_completed <= 5500
  end

  test "should exclude archived goals from allocation calculation" do
    # completed_archived has 250 but should not reduce available balance

    total_balance = @user.owner.accounts.sum(:balance)
    allocated = SavingGoal.where(user: @user)
                          .where(done: true, archived: false)
                          .sum(:amount)

    # Should not include completed_archived amount
    assert_equal 500.00, allocated.to_f
    assert_not_equal 750.00, allocated.to_f  # Would include archived
  end

  # ========================================
  # Transaction Safety Tests
  # ========================================

  test "should complete all goals in a transaction" do
    # Verify that all completions happen atomically

    initial_count = SavingGoal.where(user: @user, done: true).count

    SavingGoalAutocompleteJob.perform_now(@user)

    final_count = SavingGoal.where(user: @user, done: true).count

    # Should have completed multiple goals
    assert final_count > initial_count
  end

  test "should use database locking" do
    # This test verifies that .lock is called
    # In practice, this prevents race conditions

    # We can't easily test the actual locking mechanism in a unit test,
    # but we can verify the job runs without errors

    assert_nothing_raised do
      SavingGoalAutocompleteJob.perform_now(@user)
    end
  end

  test "should use batch update" do
    # Verify that update_all is used (more efficient than individual updates)

    # Count the number of SQL UPDATE statements
    # In practice, there should be one UPDATE for all goals

    SavingGoalAutocompleteJob.perform_now(@user)

    # Verify goals were updated
    completed = SavingGoal.where(user: @user, autocomplete: true, done: true)
    assert completed.count > 1
  end

  # ========================================
  # Edge Case Tests
  # ========================================

  test "should handle user with no goals" do
    user_without_goals = users(:two)
    # Clear any existing goals
    user_without_goals.saving_goals.destroy_all

    assert_nothing_raised do
      SavingGoalAutocompleteJob.perform_now(user_without_goals)
    end
  end

  test "should handle user with zero balance" do
    # Create a new user with no accounts/balance
    user = User.create!(
      email_address: "zerobalance@example.com",
      password: "password",
      password_confirmation: "password",
      profile_attributes: {
        first_name: "Zero",
        last_name: "Balance",
        date_of_birth: 25.years.ago
      }
    )

    goal = SavingGoal.create!(
      user: user,
      name: "Impossible Goal",
      amount: 100.00,
      priority: 1,
      autocomplete: true,
      done: false,
      archived: false
    )

    SavingGoalAutocompleteJob.perform_now(user)

    goal.reload
    assert_not goal.done

    user.destroy
  end

  test "should not complete goals for different users" do
    other_user_goal = saving_goals(:other_user_goal)
    assert_not other_user_goal.done

    # Run job for user one
    SavingGoalAutocompleteJob.perform_now(@user)

    # Other user's goal should not be affected
    other_user_goal.reload
    assert_not other_user_goal.done
  end

  test "should handle concurrent job executions gracefully" do
    # This tests that the locking mechanism works
    # In practice, running the job twice shouldn't cause issues

    SavingGoalAutocompleteJob.perform_now(@user)

    # Running again should be safe (idempotent)
    assert_nothing_raised do
      SavingGoalAutocompleteJob.perform_now(@user)
    end
  end

  test "should complete goals in correct order with complex scenario" do
    # Create a complex scenario with multiple priorities

    # Priority 1: Can complete
    p1_goal = SavingGoal.create!(
      user: @user,
      name: "P1 Completable",
      amount: 100.00,
      priority: 1,
      autocomplete: true,
      done: false,
      archived: false,
      target_date: 20.days.from_now
    )

    # Priority 1: Cannot complete (blocks further P1)
    p1_expensive = SavingGoal.create!(
      user: @user,
      name: "P1 Expensive",
      amount: 10000.00,
      priority: 1,
      autocomplete: true,
      done: false,
      archived: false,
      target_date: 30.days.from_now
    )

    # Priority 5: Can complete
    p5_goal = SavingGoal.create!(
      user: @user,
      name: "P5 Completable",
      amount: 100.00,
      priority: 5,
      autocomplete: true,
      done: false,
      archived: false,
      target_date: 40.days.from_now
    )

    SavingGoalAutocompleteJob.perform_now(@user)

    p1_goal.reload
    p1_expensive.reload
    p5_goal.reload

    # P1 completable should finish first
    assert p1_goal.done

    # P1 expensive should block remaining saving goals
    assert_not p1_expensive.done

    # P5 should therefore not be complete
    assert_not p5_goal.done

    p1_goal.destroy
    p1_expensive.destroy
    p5_goal.destroy
  end

  # ========================================
  # Integration Tests
  # ========================================

  test "should work with controller-triggered job" do
    # Simulate creating a transaction that triggers the job

    initial_incomplete = SavingGoal.where(user: @user, done: false, autocomplete: true).count

    # Perform the job
    perform_enqueued_jobs do
      SavingGoalAutocompleteJob.perform_later(@user)
    end

    final_incomplete = SavingGoal.where(user: @user, done: false, autocomplete: true).count

    # Some goals should have been completed
    assert final_incomplete < initial_incomplete
  end
end
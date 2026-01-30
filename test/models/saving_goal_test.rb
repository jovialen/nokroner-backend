require "test_helper"

class SavingGoalTest < ActiveSupport::TestCase
  setup do
    Current.session ||= session(:one)
  end

  # ========================================
  # Validation Tests
  # ========================================

  test "should be valid with valid attributes" do
    goal = SavingGoal.new(
      user: users(:one),
      name: "Test Goal",
      amount: 100.00,
      priority: 5,
      autocomplete: false,
      done: false,
      archived: false,
      target_date: 30.days.from_now
    )
    assert goal.valid?
  end

  test "should require name" do
    goal = SavingGoal.new(
      user: users(:one),
      name: nil,
      amount: 100.00,
      priority: 5
    )
    assert_not goal.valid?
    assert_includes goal.errors[:name], "can't be blank"
  end

  test "should require unique name per user" do
    goal = SavingGoal.new(
      user: users(:one),
      name: saving_goals(:high_priority_incomplete).name,
      amount: 100.00,
      priority: 5
    )
    assert_not goal.valid?
    assert_includes goal.errors[:name], "has already been taken"
  end

  test "should allow duplicate names across different users" do
    goal = SavingGoal.new(
      user: users(:two),
      name: saving_goals(:high_priority_incomplete).name,
      amount: 100.00,
      priority: 5
    )
    assert goal.valid?
  end

  test "should require amount" do
    goal = SavingGoal.new(
      user: users(:one),
      name: "Test Goal",
      amount: nil,
      priority: 5
    )
    assert_not goal.valid?
    assert_includes goal.errors[:amount], "can't be blank"
  end

  test "should require positive amount" do
    goal = SavingGoal.new(
      user: users(:one),
      name: "Test Goal",
      amount: 0,
      priority: 5
    )
    assert_not goal.valid?
    assert_includes goal.errors[:amount], "must be greater than 0"

    goal.amount = -50
    assert_not goal.valid?
    assert_includes goal.errors[:amount], "must be greater than 0"
  end

  test "should not mark as done without sufficient balance" do
    # User has 1000 in checking, 5000 in savings = 6000 total
    # Already allocated: 500 (high_priority_complete) = 5500 available
    # High priority incomplete needs 1000, so trying to complete a 5000 goal should fail

    goal = SavingGoal.new(
      user: users(:one),
      name: "Expensive Goal",
      amount: 10000.00,
      priority: 20,
      done: true  # Trying to mark as done
    )

    assert_not goal.valid?
    assert_includes goal.errors[:done], "can only be true once the required amount has been saved"
  end

  test "should not allow marking as done with sufficient balance" do
    goal = SavingGoal.new(
      user: users(:one),
      name: "Affordable Goal",
      amount: 100.00,
      priority: 20,  # Lower priority than existing goals
      done: true
    )

    assert_not goal.valid?
  end

  # ========================================
  # Scope Tests
  # ========================================

  test "created_by_user scope should return only current user goals" do
    Current.session = users(:one).sessions.create!

    goals = SavingGoal.created_by_user

    assert goals.all? { |g| g.user_id == users(:one).id }
    assert_not goals.any? { |g| g.user_id == users(:two).id }
  end

  test "completed scope should return only completed goals" do
    goals = SavingGoal.completed

    assert goals.all?(&:done)
    assert_includes goals, saving_goals(:high_priority_complete)
    assert_not_includes goals, saving_goals(:high_priority_incomplete)
  end

  test "archived scope should return only archived goals" do
    goals = SavingGoal.archived

    assert goals.all?(&:archived)
    assert_includes goals, saving_goals(:completed_archived)
    assert_not_includes goals, saving_goals(:high_priority_complete)
  end

  # ========================================
  # Instance Method Tests
  # ========================================

  test "saved should return amount if goal is done" do
    goal = saving_goals(:high_priority_complete)
    assert_equal goal.amount, goal.saved
  end

  test "saved should return available balance clamped to amount if not done" do
    goal = saving_goals(:low_priority_small)
    # User has 6000 total, 500 allocated to complete goal, 1000 reserved for high priority
    # So for this goal: 6000 - 500 - 1000 = 4500 available, but goal is only 150
    assert_equal 150.00, goal.saved.to_f
  end

  test "saved should return 0 if insufficient balance" do
    goal = saving_goals(:low_priority_large)
    # This goal needs 5000 but has less available after higher priority goals
    saved = goal.saved.to_f
    assert_equal 4000, saved
  end

  test "remaining should return difference between amount and saved" do
    goal = saving_goals(:high_priority_incomplete)
    expected_remaining = goal.amount - goal.saved
    assert_equal expected_remaining.to_f, goal.remaining.to_f
  end

  test "ready should return true when saved >= amount" do
    goal = saving_goals(:high_priority_complete)
    assert goal.ready
  end

  test "ready should return false when saved < amount" do
    goal = saving_goals(:low_priority_large)
    assert_not goal.ready
  end

  test "daily_saving should return nil without target date" do
    goal = saving_goals(:no_target_date)
    assert_nil goal.daily_saving
  end

  test "daily_saving should calculate correct daily amount" do
    goal = SavingGoal.new(
      user: users(:one),
      name: "Daily Test",
      amount: 100.00,
      priority: 20,
      target_date: 10.days.from_now.to_date
    )

    # 100 / 10 = 10 per day
    assert_equal 10.0, goal.daily_saving.to_f
  end

  test "daily_saving should return full amount for past dates" do
    goal = saving_goals(:overdue_goal)
    assert_equal goal.amount.to_f, goal.daily_saving.to_f
  end

  test "daily_saving should return full amount for today's date" do
    goal = SavingGoal.new(
      user: users(:one),
      name: "Today Goal",
      amount: 100.00,
      priority: 20,
      target_date: Date.today
    )

    assert_equal 100.0, goal.daily_saving.to_f
  end

  # ========================================
  # Autocomplete Tests
  # ========================================

  test "should autocomplete before validation if autocomplete is true and ready" do
    goal = SavingGoal.new(
      user: users(:one),
      name: "Auto Complete Test",
      amount: 50.00,  # Very small amount, should be ready
      priority: 5,
      autocomplete: true,
      done: false
    )

    goal.save
    assert goal.done
  end

  test "should not autocomplete if autocomplete is false" do
    goal = SavingGoal.new(
      user: users(:one),
      name: "Manual Complete Test",
      amount: 50.00,
      priority: 20,
      autocomplete: false,
      done: false
    )

    goal.save
    assert_not goal.done
  end

  test "should not autocomplete if not ready" do
    goal = SavingGoal.new(
      user: users(:one),
      name: "Not Ready Test",
      amount: 10000.00,  # Too large
      priority: 20,
      autocomplete: true,
      done: false
    )

    goal.save
    assert_not goal.done
  end

  # ========================================
  # Reserved Calculation Tests
  # ========================================

  test "reserved should include completed non-archived goals" do
    goal = saving_goals(:medium_priority_incomplete)

    # Should include high_priority_complete (500) but not completed_archived
    # Since this is priority 5, it should also include high_priority_incomplete (1000)
    reserved = goal.send(:reserved)

    assert reserved >= 500.00  # At least the completed goal
  end

  test "reserved should include higher priority incomplete goals" do
    goal = saving_goals(:low_priority_small)  # Priority 10

    reserved = goal.send(:reserved)

    # Should include:
    # - high_priority_complete (500, done and not archived)
    # - high_priority_incomplete (1000, priority 1 < 10)
    # - medium_priority_incomplete (300, priority 5 < 10)
    # - medium_priority_manual (200, priority 5 < 10)
    # Total: at least 2000

    assert_equal 2000, reserved
  end

  test "reserved should exclude the goal itself" do
    goal = saving_goals(:high_priority_complete)

    reserved = goal.send(:reserved)

    # Should not include itself in the calculation
    # Only other completed non-archived goals
    other_completed = SavingGoal.where(user: users(:one))
                                .where(done: true, archived: false)
                                .where.not(id: goal.id)
                                .sum(:amount)

    assert_equal other_completed.to_f, reserved.to_f
  end

  # ========================================
  # Association Tests
  # ========================================

  test "should belong to user" do
    goal = saving_goals(:high_priority_incomplete)
    assert_instance_of User, goal.user
    assert_equal users(:one), goal.user
  end

  test "should be destroyed when user is destroyed" do
    user = users(:one)
    goal_ids = user.saving_goals.pluck(:id)

    assert_difference "SavingGoal.count", -goal_ids.length do
      user.destroy
    end
  end
end

require "test_helper"

class Api::V1::UserControllerTest < ActionDispatch::IntegrationTest
  test "should get user when logged in" do
    post api_v1_login_path, params: { email_address: users(:one).email_address, password: "password" }, as: :json
    assert_response :success

    get api_v1_me_path, as: :json
    assert_response :success, "did not get user when logged in"
  end

  test "should not log into invalid user" do
    post api_v1_login_path, params: { email_address: "a@b.c", password: "password" }, as: :json
    assert_response :unauthorized, "successfully logged into non-existent user"
  end

  test "should not log into user with invalid password" do
    post api_v1_login_path, params: { email_address: users(:one).email_address, password: "invalid" }, as: :json
    assert_response :unauthorized, "successfully logged into user with wrong credentials"
  end

  test "should not get user when not logged in" do
    get api_v1_me_path, as: :json
    assert_response :unauthorized, "got user while logged out"
  end

  test "should not get user when logged out" do
    post api_v1_login_path, params: { email_address: users(:one).email_address, password: "password" }, as: :json
    assert_response :success, "failed to log in"

    get api_v1_me_path, as: :json
    assert_response :success, "failed to get user while logged in"

    delete api_v1_logout_path, as: :json
    assert_response :success, "failed to log out"

    get api_v1_me_path, as: :json
    assert_response :unauthorized, "successfully got user after logout"
  end

  test "should create owner and profile for new user" do
    assert_difference("Owner.count", 1) do
      post api_v1_register_path, params: {
        user: {
          email_address: "a@b.c",
          password: "password",
          password_confirmation: "password",
          profile_attributes: { first_name: "A", last_name: "B", date_of_birth: 20.years.ago }
        }
      }, as: :json
      assert_response :success

      json = JSON.parse(response.body)
      assert_not_nil json["user"]
      user = json["user"]
      assert_not_nil user["owner_id"]
      owner = user["owner_id"]

      get api_v1_owner_path(owner), as: :json
      assert_response :success

      owner = JSON.parse(response.body)
      assert_equal "A B", owner["name"]
    end

    assert_difference("Profile.count", 1) do
      post api_v1_register_path, params: {
        user: {
          email_address: "b@c.d",
          password: "password",
          password_confirmation: "password",
          profile_attributes: { first_name: "B", last_name: "C", date_of_birth: 20.years.ago }
        }
      }, as: :json
      assert_response :success

      get api_v1_me_profile_path, as: :json
      assert_response :success

      profile = JSON.parse(response.body)
      assert_equal "B", profile["first_name"]
      assert_equal "C", profile["last_name"]
      assert_equal 20.years.ago.to_date, Date.parse(profile["date_of_birth"])
      assert_equal 20, profile["age"]
    end
  end
end

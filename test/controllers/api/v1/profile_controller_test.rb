require "test_helper"

class Api::V1::ProfileControllerTest < ActionDispatch::IntegrationTest
  setup do
    post api_v1_login_path, params: { email_address: users(:one).email_address, password: "password" }, as: :json
    assert_response :success, "failed to log into user"
  end

  test "should get profile" do
    get api_v1_me_profile_path, as: :json
    assert_response :success

    profile = JSON.parse(response.body)
    assert_equal profiles(:one).first_name, profile["first_name"]
    assert_equal profiles(:one).last_name, profile["last_name"]
    assert profile.key?("age"), "response should include age method"
  end

  test "should update profile" do
    patch api_v1_me_profile_path, params: { profile: { first_name: "Jane", last_name: "Smith" } }, as: :json
    assert_response :success

    profile = JSON.parse(response.body)
    assert_equal "Jane", profile["first_name"]
    assert_equal "Smith", profile["last_name"]

    profiles(:one).reload
    assert_equal "Jane", profiles(:one).first_name
    assert_equal "Smith", profiles(:one).last_name
  end

  test "should update profile date of birth" do
    new_date = "1990-05-15"

    patch api_v1_me_profile_path, params: { profile: { date_of_birth: new_date } }, as: :json
    assert_response :success

    profiles(:one).reload
    assert_equal Date.parse(new_date), profiles(:one).date_of_birth
  end

  test "should not update profile with invalid first_name" do
    original_first_name = profiles(:one).first_name

    patch api_v1_me_profile_path, params: { profile: { first_name: nil } }, as: :json
    assert_response :unprocessable_entity

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")
    assert_kind_of Array, response_body["errors"]

    profiles(:one).reload
    assert_equal original_first_name, profiles(:one).first_name
  end

  test "should not update profile with invalid date_of_birth" do
    original_dob = profiles(:one).date_of_birth

    patch api_v1_me_profile_path, params: { profile: { date_of_birth: nil } }, as: :json
    assert_response :unprocessable_entity

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")

    profiles(:one).reload
    assert_equal original_dob, profiles(:one).date_of_birth
  end

  test "should update only allowed profile attributes" do
    patch api_v1_me_profile_path, params: { profile: { first_name: "John" } }, as: :json
    assert_response :success

    profile = JSON.parse(response.body)
    assert_equal "John", profile["first_name"]
  end
end
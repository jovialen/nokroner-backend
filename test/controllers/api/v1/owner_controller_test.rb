require "test_helper"

class Api::V1::OwnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    post api_v1_login_path, params: { email_address: users(:one).email_address, password: "password" }, as: :json
    assert_response :success, "failed to log into user"
  end

  test "should get owner" do
    get api_v1_owner_path(owners(:one)), as: :json
    assert_response :success
  end

  test "should not get owner created by another user" do
    get api_v1_owner_path(owners(:other_user_owner)), as: :json
    assert_response :not_found
  end

  test "should get all owners" do
    get api_v1_owners_path, as: :json
    assert_response :success

    owners = JSON.parse(response.body)
    assert_equal 2, owners.length, "should be 2 owners"
  end

  test "should only get owners created by current user" do
    get api_v1_owners_path, as: :json
    assert_response :success

    owners = JSON.parse(response.body)
    owner_ids = owners.map { |o| o["id"] }

    assert_includes owner_ids, owners(:one).id
    assert_includes owner_ids, owners(:two).id
    assert_not_includes owner_ids, owners(:other_user_owner).id
  end

  test "should create owner" do
    assert_difference("Owner.count") do
      post api_v1_owners_path, params: { owner: { name: "New Owner" } }, as: :json
      assert_response :created
    end

    owner = JSON.parse(response.body)
    assert_equal "New Owner", owner["name"]

    created_owner = Owner.find(owner["id"])
    assert_equal users(:one).id, created_owner.created_by_id
  end

  test "should not create owner with invalid params" do
    assert_no_difference("Owner.count") do
      post api_v1_owners_path, params: { owner: { name: nil } }, as: :json
      assert_response :unprocessable_entity
    end

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")
    assert_kind_of Array, response_body["errors"]
  end

  test "should update owner" do
    patch api_v1_owner_path(owners(:one)), params: { owner: { name: "Bob" } }, as: :json
    assert_response :success

    owner = JSON.parse(response.body)
    assert_equal "Bob", owner["name"]

    owners(:one).reload
    assert_equal "Bob", owners(:one).name
  end

  test "should not update owner with invalid params" do
    original_name = owners(:one).name

    patch api_v1_owner_path(owners(:one)), params: { owner: { name: nil } }, as: :json
    assert_response :unprocessable_entity

    response_body = JSON.parse(response.body)
    assert response_body.key?("errors")

    owners(:one).reload
    assert_equal original_name, owners(:one).name
  end

  test "should not update owner created by another user" do
    patch api_v1_owner_path(owners(:other_user_owner)), params: { owner: { name: "Bob" } }, as: :json
    assert_response :not_found
  end

  test "should destroy owner" do
    assert_difference("Owner.count", -1) do
      delete api_v1_owner_path(owners(:one)), as: :json
      assert_response :ok
    end
  end

  test "should not destroy owner created by another user" do
    assert_no_difference("Owner.count") do
      delete api_v1_owner_path(owners(:other_user_owner)), as: :json
      assert_response :not_found
    end
  end
end

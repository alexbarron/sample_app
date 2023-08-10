require "test_helper"

class UsersSignupTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  test "should not accept invalid users" do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: { user: {
        name: "",
        email: "email@invalid",
        password: "f",
        password_confirmation: "b"
      }}
    end
    assert_response :unprocessable_entity
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'li', "Password is too short (minimum is 6 characters)"
  end

  test "should accept valid users" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: {
        name: "My Name",
        email: "email@valid.com",
        password: "fyodor",
        password_confirmation: "fyodor"
      }}
    follow_redirect!
    assert_template 'users/show'
    assert_select 'div.alert-success'
    assert is_logged_in?
    end
  end
end

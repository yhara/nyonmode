require 'test_helper'

class TokopuyosControllerTest < ActionController::TestCase
  setup do
    @tokopuyo = tokopuyos(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tokopuyos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create tokopuyo" do
    assert_difference('Tokopuyo.count') do
      post :create, tokopuyo: {  }
    end

    assert_redirected_to tokopuyo_path(assigns(:tokopuyo))
  end

  test "should show tokopuyo" do
    get :show, id: @tokopuyo
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @tokopuyo
    assert_response :success
  end

  test "should update tokopuyo" do
    patch :update, id: @tokopuyo, tokopuyo: {  }
    assert_redirected_to tokopuyo_path(assigns(:tokopuyo))
  end

  test "should destroy tokopuyo" do
    assert_difference('Tokopuyo.count', -1) do
      delete :destroy, id: @tokopuyo
    end

    assert_redirected_to tokopuyos_path
  end
end

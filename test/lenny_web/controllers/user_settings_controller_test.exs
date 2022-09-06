defmodule LennyWeb.UserSettingsControllerTest do
  use LennyWeb.ConnCase, async: true

  alias Lenny.Accounts
  import Lenny.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/email" do
    test "renders change email page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit_email))
      response = html_response(conn, 200)
      assert response =~ "Change Email"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit_email))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "GET /users/password" do
    test "renders change password page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit_password))
      response = html_response(conn, 200)
      assert response =~ "Change Password"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit_password))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "GET /users/settings" do
    test "renders change settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit_password))
      response = html_response(conn, 200)
      assert response =~ "Settings"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit_password))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "PUT /users/password (change password form)" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.live_path(conn, LennyWeb.CallsLive)
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "Change Password"
      assert response =~ "should be at least 6 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/email (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      old_email = user.email
      new_email = unique_user_email()

      conn =
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => valid_user_password(),
          "user" => %{"email" => new_email}
        })

      assert redirected_to(conn) == Routes.live_path(conn, LennyWeb.CallsLive)
      assert get_flash(conn, :info) =~ "Email address updated successfully"
      refute Accounts.get_user_by_email(old_email)
      assert Accounts.get_user_by_email(new_email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Change Email"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end
end

defmodule LennyWeb.UserRegistrationControllerTest do
  use LennyWeb.ConnCase, async: true

  import Lenny.AccountsFixtures

  describe "GET /users/register" do
    test "renders registration page", %{conn: conn} do
      conn = get(conn, Routes.user_registration_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ ~r{<h1.*>\s*Register}
      assert response =~ ~r{<a.*>\s*Log in}
      assert response =~ ~r{<a.*>\s*Register}
    end

    test "redirects if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(Routes.user_registration_path(conn, :new))
      assert redirected_to(conn) == "/lenny"
    end
  end

  describe "POST /users/register" do
    @tag :capture_log
    test "creates account and logs the user in", %{conn: conn} do
      email = unique_user_email()

      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => valid_user_attributes(email: email)
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == "/lenny"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/lenny")
      assert "/lenny/new" = redir_path = redirected_to(conn, 302)

      conn = get(recycle(conn), redir_path)
      response = html_response(conn, 200)
      assert response =~ email
      assert response =~ ~r{<a.*>\s*Settings}
      assert response =~ ~r{<a.*>\s*Log out}
    end

    test "render errors for invalid data", %{conn: conn} do
      conn =
        post(conn, Routes.user_registration_path(conn, :create), %{
          "user" => %{"email" => "with spaces", "password" => "too short"}
        })

      response = html_response(conn, 200)
      assert response =~ ~r{<h1.*>\s*Register}
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
    end
  end
end

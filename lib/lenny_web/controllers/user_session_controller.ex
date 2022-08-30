defmodule LennyWeb.UserSessionController do
  use LennyWeb, :controller

  alias Lenny.Accounts
  alias LennyWeb.UserAuth

  def new(conn, _params) do
    conn
    |> assign(:remember_me, true)
    |> assign(:error_message, nil)
    |> render("new.html")
  end

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.get_user_by_email_and_password(email, password) do
      UserAuth.log_in_user(conn, user, user_params)
    else
      conn
      |> assign(:error_message, "Invalid email or password")
      |> assign(:remember_me, user_params["remember_me"] == "true")
      |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end

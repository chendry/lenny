defmodule LennyWeb.UserSettingsController do
  use LennyWeb, :controller

  alias Lenny.Accounts
  alias Lenny.PhoneNumbers
  alias LennyWeb.UserAuth

  def edit_email(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> assign(:changeset, Accounts.change_user_email(user))
    |> render("edit_email.html")
  end

  def edit_password(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> assign(:changeset, Accounts.change_user_password(user))
    |> render("edit_password.html")
  end

  def edit_settings(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> assign(:changeset, Accounts.change_user_settings(user))
    |> render("edit_settings.html")
  end

  def edit_phone(conn, _params) do
    user = conn.assigns.current_user

    conn
    |> assign(:verified_phone_number, PhoneNumbers.get_verified_phone_number(user))
    |> render("edit_phone.html")
  end

  def update_email(conn, params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_email(user, password, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email address updated successfully.")
        |> redirect(to: Routes.live_path(conn, LennyWeb.CallsLive))

      {:error, changeset} ->
        render(conn, "edit_email.html", changeset: changeset)
    end
  end

  def update_password(conn, params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, Routes.live_path(conn, LennyWeb.CallsLive))
        |> UserAuth.log_in_user(user)

      {:error, changeset} ->
        render(conn, "edit_password.html", changeset: changeset)
    end
  end

  def update_settings(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_settings(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Settings updated successfully.")
        |> redirect(to: Routes.live_path(conn, LennyWeb.CallsLive))

      {:error, changeset} ->
        render(conn, "edit_settings.html", changeset: changeset)
    end
  end
end

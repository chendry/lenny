defmodule LennyWeb.LennyLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    {:ok,
     socket
     |> assign(:current_user, Accounts.get_user_by_session_token(user_token))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Lenny</h1>
    <p><%= @current_user.email %></p>
    """
  end
end

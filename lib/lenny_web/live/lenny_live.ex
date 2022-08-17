defmodule LennyWeb.LennyLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.PhoneNumbers
  alias Lenny.PhoneNumbers.PhoneNumber

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:changeset, PhoneNumber.changeset(%PhoneNumber{}, %{}))
     |> assign(:pending_phone_number, PhoneNumbers.get_pending_phone_number(user))
     |> assign(:approved_phone_number, PhoneNumbers.get_approved_phone_number(user))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Lenny</h1>
    <p><%= @user.email %></p>

    <%= if @pending_phone_number == nil and @approved_phone_number == nil do %>
      <.form for={@changeset} let={f} phx-submit="register_phone_number">
        <%= telephone_input f, :phone %>
        <%= error_tag f, :phone %>
        <%= submit "Submit" %>
      </.form>
    <% end %>

    <%= if @pending_phone_number do %>
    <% end %>

    <p><%= inspect @pending_phone_number %></p>
    <p><%= inspect @approved_phone_number %></p>
    <p><%= inspect @changeset %></p>
    """
  end

  @impl true
  def handle_event("register_phone_number", %{"phone_number" => %{"phone" => phone}}, socket) do
    case PhoneNumbers.register_phone_number_and_start_verification(socket.assigns.user, phone) do
      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:ok, phone_number} ->
        {:noreply, assign(socket, :pending_phone_number, phone_number)}
    end
  end
end

defmodule LennyWeb.LennyLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.PhoneNumbers
  alias Lenny.PhoneNumbers.PhoneNumber
  alias Lenny.PhoneNumbers.VerificationForm

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:phone_number_changeset, PhoneNumber.changeset(%PhoneNumber{}, %{}))
     |> assign(:verification_changeset, VerificationForm.changeset(%VerificationForm{}, %{}))
     |> assign(:pending_phone_number, PhoneNumbers.get_pending_phone_number(user))
     |> assign(:approved_phone_number, PhoneNumbers.get_approved_phone_number(user))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Lenny</h1>
    <p><%= @user.email %></p>

    <%= if @pending_phone_number == nil and @approved_phone_number == nil do %>
      Register Phone Number:
      <.form for={@phone_number_changeset} let={f} phx-submit="register_phone_number">
        <%= telephone_input f, :phone %>
        <%= error_tag f, :phone %>
        <%= submit "Submit" %>
      </.form>
    <% end %>

    <%= if @pending_phone_number do %>
      Verify Phone Number:
      <.form for={@verification_changeset} let={f} phx-submit="verify_phone_number">
        <%= text_input f, :code %>
        <%= error_tag f, :code %>
        <%= submit "Submit" %>
      </.form>
    <% end %>

    <p><%= inspect @pending_phone_number %></p>
    <p><%= inspect @approved_phone_number %></p>
    """
  end

  @impl true
  def handle_event("register_phone_number", %{"phone_number" => phone_number_params}, socket) do
    PhoneNumbers.register_phone_number_and_start_verification(
      socket.assigns.user,
      phone_number_params
    )
    |> case do
      {:ok, phone_number} ->
        {:noreply, assign(socket, :pending_phone_number, phone_number)}

      {:error, changeset} ->
        {:noreply, assign(socket, :phone_number_changeset, changeset)}
    end
  end

  @impl true
  def handle_event(
        "verify_phone_number",
        %{"verification_form" => verification_form_params},
        socket
      ) do
    PhoneNumbers.verify_phone_number(
      socket.assigns.pending_phone_number,
      verification_form_params
    )
    |> case do
      {:ok, phone_number} ->
        {:noreply,
         socket
         |> assign(:pending_phone_number, nil)
         |> assign(:approved_phone_number, phone_number)}

      {:error, changeset} ->
        {:noreply, assign(socket, :verification_changeset, changeset)}
    end
  end
end

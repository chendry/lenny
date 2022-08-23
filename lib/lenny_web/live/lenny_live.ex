defmodule LennyWeb.LennyLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.Twilio
  alias Lenny.Calls
  alias Lenny.PhoneNumbers
  alias Lenny.PhoneNumbers.PhoneNumber
  alias Lenny.PhoneNumbers.VerificationForm

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    phone_number = PhoneNumbers.get_approved_phone_number(user)
    call = phone_number && Calls.get_active_call(phone_number.phone)

    if connected?(socket) do
      if phone_number != nil do
        Phoenix.PubSub.subscribe(Lenny.PubSub, "call:#{phone_number.phone}")
      end
    end

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:sid, call && call.sid)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    user = socket.assigns.user

    {:noreply,
     socket
     |> assign(:pending_phone_number, PhoneNumbers.get_pending_phone_number(user))
     |> assign(:approved_phone_number, PhoneNumbers.get_approved_phone_number(user))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    cond do
      socket.assigns.approved_phone_number == nil ->
        push_patch(socket, to: "/lenny/new")

      socket.assigns.pending_phone_number ->
        push_patch(socket, to: "/lenny/verify")

      true ->
        socket
    end
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:changeset, PhoneNumber.changeset())
  end

  defp apply_action(socket, :verify, _params) do
    socket
    |> assign(:changeset, VerificationForm.changeset())
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto pt-4">
      <%= if @live_action == :index do %>
        <%= if @approved_phone_number do %>
          <h1 class="text-3xl font-bold mb-4">
            <%= if @sid == nil do %>
              Waiting for a forwarded call...
            <% else %>
              Active call: <%= @sid %>
            <% end %>
          </h1>
        <% end %>
        <%= live_patch "Change", to: "/lenny/new", class: "text-blue-600" %>
      <% end %>

      <%= if @live_action == :new do %>
        <h1 class="text-3xl font-bold mb-4">
          <%= if @approved_phone_number == nil do %>
            Register a phone number
          <% else %>
            Change your phone number
          <% end %>
        </h1>

        <.form for={@changeset} let={f} phx-submit="register_phone_number">
          <div class="flex flex-col space-y-2">
            <%= label f, :phone do %>
              Phone Number (format: "+15554443333")
            <% end %>
            <%= telephone_input f, :phone %>
            <%= error_tag f, :phone %>
          </div>

          <div class="mt-4">
            <%= submit "Submit", class: "bg-blue-600 rounded-md text-white font-bold px-2 py-1" %>
            <%= if @approved_phone_number do %>
              <%= live_patch "Cancel", to: "/lenny", class: "ml-4 text-blue-600" %>
            <% end %>
          </div>
        </.form>
      <% end %>

      <%= if @live_action == :verify do %>
        <h1 class="text-3xl font-bold mb-4">
          Verify your phone number:
        </h1>

        <p class="my-2">
          <%= @pending_phone_number.phone %>
        </p>

        <.form for={@changeset} let={f} phx-submit="verify_phone_number">
          <div class="flex flex-col space-y-2">
            <%= label f, :code %>
            <%= text_input f, :code %>
            <%= error_tag f, :code %>
          </div>

          <div class="mt-4">
            <%= submit "Submit", class: "bg-blue-600 rounded-md text-white font-bold px-2 py-1" %>
            <a href="#" phx-click="cancel_verification" class="ml-4 text-blue-600">
              Cancel
            </a>
          </div>
        </.form>
      <% end %>

      <div class="mt-4">
        <%= if @approved_phone_number do %>
          <div>Approved: <%= @approved_phone_number.phone %></div>
        <% end %>
        <%= if @pending_phone_number do %>
          <div>Pending: <%= @pending_phone_number.phone %></div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("register_phone_number", %{"phone_number" => phone_number_params}, socket) do
    PhoneNumbers.register_phone_number_and_start_verification(
      socket.assigns.user,
      phone_number_params
    )
    |> case do
      {:ok, _phone_number} ->
        {:noreply, push_patch(socket, to: "/lenny/verify")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
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
      {:ok, _phone_number} ->
        {:noreply, push_patch(socket, to: "/lenny")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}

      {:stop, message} ->
        PhoneNumbers.soft_delete_phone_number(socket.assigns.pending_phone_number)

        {:noreply,
         socket
         |> put_flash(:error, message)
         |> push_patch(to: "/lenny")}
    end
  end

  @impl true
  def handle_event("cancel_verification", _params, socket) do
    phone_number = socket.assigns.pending_phone_number

    if phone_number do
      Twilio.verify_cancel(phone_number.sid)
      PhoneNumbers.soft_delete_phone_number(phone_number)
    end

    {:noreply, push_patch(socket, to: "/lenny")}
  end

  @impl true
  def handle_info({:call, :started, sid}, socket) do
    {:noreply, assign(socket, :sid, sid)}
  end

  @impl true
  def handle_info({:call, :ended}, socket) do
    {:noreply, assign(socket, :sid, nil)}
  end
end

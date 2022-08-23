defmodule LennyWeb.CallLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.Calls
  alias Lenny.PhoneNumbers

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    phone_number = PhoneNumbers.get_approved_phone_number(user)

    if phone_number == nil do
      {:ok, push_redirect(socket, to: "/phone/new")}
    else
      if connected?(socket) do
        Phoenix.PubSub.subscribe(Lenny.PubSub, "call:#{phone_number.phone}")
      end

      call = Calls.get_active_call(phone_number.phone)

      {:ok,
       socket
       |> assign(:phone_number, phone_number)
       |> assign(:sid, call && call.sid)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto pt-4 px-2">
      <h1 class="text-3xl font-bold">
        <%= if @sid == nil do %>
          Waiting for a forwarded call...
        <% else %>
          Active call: <%= @sid %>
        <% end %>
      </h1>
      <p class="mt-4">
        Approved: <%= @phone_number.phone %>
      </p>
      <p class="mt-4">
        <%= live_redirect "Change number", to: "/phone/new", class: "text-blue-600" %>
      </p>
    </div>
    """
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

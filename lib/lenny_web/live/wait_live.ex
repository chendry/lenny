defmodule LennyWeb.WaitLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.Calls
  alias Lenny.PhoneNumbers

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    phone_number = PhoneNumbers.get_approved_phone_number(user)

    if phone_number == nil do
      {:ok, push_redirect(socket, to: "/phone_numbers/new")}
    else
      call = Calls.get_active_call(phone_number.phone)

      if call do
        {:ok, push_redirect(socket, to: "/calls/#{call.sid}")}
      else
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Lenny.PubSub, "wait:#{phone_number.phone}")
        end

        {:ok, assign(socket, :phone_number, phone_number)}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto pt-4 pb-12 px-2">
      <h1 class="text-3xl font-bold">
        Waiting for a forwarded call...
      </h1>
      <p class="mt-4">
        Approved: <%= @phone_number.phone %>
        (<%= live_redirect "Change number", to: "/phone_numbers/new", class: "text-blue-600" %>)
      </p>
    </div>
    """
  end

  @impl true
  def handle_info({:call_started, sid}, socket) do
    {:noreply, push_redirect(socket, to: "/calls/#{sid}")}
  end
end

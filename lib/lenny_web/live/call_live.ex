defmodule LennyWeb.CallLive do
  use LennyWeb, :live_view

  alias Lenny.Twilio
  alias Lenny.Accounts
  alias Lenny.Calls
  alias Lenny.PhoneNumbers
  alias LennyWeb.AudioFileUrls

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    phone_number = PhoneNumbers.get_approved_phone_number(user)

    if phone_number == nil do
      {:ok, push_redirect(socket, to: "/phone_numbers/new")}
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
        <%= live_redirect "Change number", to: "/phone_numbers/new", class: "text-blue-600" %>
      </p>

      <%= if @sid do %>
        <button phx-click="say" value="01">01</button>
        <button phx-click="say" value="02">02</button>
        <button phx-click="say" value="03">03</button>
        <button phx-click="say" value="04">04</button>
        <button phx-click="say" value="05">05</button>
        <button phx-click="say" value="06">06</button>
        <button phx-click="say" value="07">07</button>
        <button phx-click="say" value="08">08</button>
        <button phx-click="say" value="09">09</button>
        <button phx-click="say" value="10">10</button>
        <button phx-click="say" value="11">11</button>
        <button phx-click="say" value="12">12</button>
        <button phx-click="say" value="13">13</button>
        <button phx-click="say" value="14">14</button>
        <button phx-click="say" value="15">15</button>
        <button phx-click="say" value="16">16</button>
        <button phx-click="say" value="17">17</button>
        <button phx-click="say" value="18">18</button>
        <button phx-click="say" value="19">19</button>
      <% end %>
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

  @impl true
  def handle_event("say", %{"value" => i}, socket) do
    Twilio.modify_call(
      socket.assigns.sid,
      """
      <Response>
        <Play>
          #{AudioFileUrls.lenny(String.to_integer(i))}
        </Play>
        <Pause length="120" />
      </Response>
      """
    )

    {:noreply, socket}
  end
end

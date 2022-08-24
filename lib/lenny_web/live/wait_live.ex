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
      if PhoneNumbers.get_pending_phone_number(user) do
        {:ok, push_redirect(socket, to: "/phone_numbers/verify")}
      else
        case Calls.get_active_calls(phone_number.phone) do
          [call] ->
            {:ok, push_redirect(socket, to: "/calls/#{call.sid}")}

          calls ->
            if connected?(socket) do
              Phoenix.PubSub.subscribe(Lenny.PubSub, "wait:#{phone_number.phone}")
            end

            {:ok,
            socket
            |> assign(:phone_number, phone_number)
            |> assign(:calls, calls)}
        end
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto pt-4 pb-12 px-2">
      <h1 class="text-3xl font-bold">
        Waiting for Your Call
      </h1>
      <p class="mt-4">
        This page will automatically refresh when we receive a call from your phone number:
      </p>
      <div class="text-center">
        <div class="mt-4 text-center text-green-600 text-xl font-bold tracking-[0.25rem]">
          <span id="approved-number"><%= @phone_number.phone %></span>
        </div>
        <p>
          <%= live_redirect "Change Number", to: "/phone_numbers/new", class: "text-blue-600" %>
        </p>
      </div>
      <%= if not Enum.empty?(@calls) do %>
        <ul id="calls">
          <%= for call <- @calls do %>
            <li>
              <%= live_redirect call.forwarded_from || call.from, to: "/calls/#{call.sid}" %>
            </li>
          <% end %>
        </ul>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_info({:call_started, sid}, socket) do
    {:noreply, push_redirect(socket, to: "/calls/#{sid}")}
  end
end

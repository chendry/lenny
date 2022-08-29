defmodule LennyWeb.WaitLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.Calls
  alias Lenny.PhoneNumbers

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    phone_number = PhoneNumbers.get_approved_phone_number(user)

    cond do
      phone_number == nil ->
        {:ok, push_redirect(socket, to: "/phone_numbers/new")}

      PhoneNumbers.get_pending_phone_number(user) ->
        {:ok, push_redirect(socket, to: "/phone_numbers/verify")}

      sid = Calls.get_sole_unseen_active_call_for_user(user.id) ->
        {:ok, push_redirect(socket, to: "/calls/#{sid}")}
        
      true ->
        if connected?(socket) do
          Phoenix.PubSub.subscribe(Lenny.PubSub, "wait:#{phone_number.phone}")
        end

        {:ok,
         socket
         |> assign(:phone_number, phone_number)
         |> assign(:call_history_report, Calls.call_history_report(user.id))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto mt-6 pb-12 px-2">
      <div class="mx-6 sm:mx-0">
        <div class="bg-slate-100 border border-slate-600 rounded-lg shadow-md p-4 text-center">
          <h1 class="text-xl font-bold">
            Your Verified Phone Number
          </h1>
          <div class="text-green-800 text-xl font-bold tracking-[0.25rem]">
            <span id="approved-number"><%= @phone_number.phone %></span>
          </div>
          <div class="mt-1">
            <%= live_redirect "Change Number", to: "/phone_numbers/new", class: "text-blue-800 text-sm font-bold" %>
          </div>
        </div>

        <p class="mt-6 text-sm sm:text-base">
          This page automatically refreshes when you call
          <span class="font-bold whitespace-nowrap">938-4GO-LENNY</span>
          from your verified phone number.
        </p>
      </div>

      <h1 class="mt-6 text-center auto text-lg font-bold">
        Call History
      </h1>

      <div class="flex flex-col mt-2 border-t sm:border sm:rounded-lg sm:overflow-hidden border-gray-400 -mx-2">
        <%= for row <- @call_history_report do %>
          <%= live_redirect to: "/calls/#{row.sid}" do %>
            <div class="bg-gray-100 py-2 px-6 border-b border-gray-400">
              <div class="flex flex-row justify-between">
                <span>
                  <span class="font-bold"><%= Calls.format_timestamp_date(row.started_at) %></span>
                  <span class="ml-2"><%= Calls.format_timestamp_time(row.started_at) %></span>
                </span>

                <span class="font-bold">
                  <%= if row.ended_at == nil do %>
                    <span class="text-green-700">Connected</span>
                  <% else %>
                    <span class="text-gray-600">
                      <%= Calls.format_duration(row.started_at, row.ended_at) %>
                    </span>
                  <% end %>
              </span>
              </div>

              <div class="flex flex-row justify-between">
                <span class="tracking-widest">
                  <%= row.from %>
                </span>
                <%= if row.recorded do %>
                  <span class="font-bold text-red-800">Recorded</span>
                <% end %>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_info({:call_started, sid}, socket) do
    {:noreply, push_redirect(socket, to: "/calls/#{sid}")}
  end
end

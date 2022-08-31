defmodule LennyWeb.CallsLive do
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

          Calls.get_active_calls_for_user(user.id)
          |> Enum.each(fn call ->
            Phoenix.PubSub.subscribe(Lenny.PubSub, "call:#{call.sid}")
          end)
        end

        {:ok,
         socket
         |> assign(:user, user)
         |> assign(:phone_number, phone_number)
         |> assign_call_history()}
    end
  end

  def breadcrumbs(assigns) do
    ~H"""
    <div id="breadcrumbs">
      <span>Calls</span>
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto mt-6 pb-12">
      <div class="px-6 sm:px-0">
        <div class="bg-slate-100 border border-slate-600 rounded-lg shadow-md p-4 text-center">
          <h1 class="text-xl font-bold">
            Your Verified Phone Number
          </h1>
          <div class="text-green-600 text-xl font-bold tracking-[0.25rem]">
            <span id="approved-number"><%= @phone_number.phone %></span>
          </div>
          <div class="mt-1">
            <%= live_redirect "Change Number", to: "/phone_numbers/new", class: "text-blue-600 text-sm font-bold" %>
          </div>
        </div>

        <p class="mt-6 text-sm sm:text-base">
          This page automatically refreshes when you call
          <span class="font-bold whitespace-nowrap">938-GOLENNY</span>
          from your verified phone number.
        </p>
      </div>

      <%= if not Enum.empty?(@call_history) do %>
        <h1 class="mt-6 text-center auto text-lg font-bold">
          Call History
        </h1>

        <div class="flex flex-col mt-2 border-y sm:border sm:rounded-lg sm:overflow-hidden border-gray-400">
          <%= for row <- @call_history do %>
            <%= live_redirect to: "/calls/#{row.sid}" do %>
              <%= if row != List.first(@call_history) do %>
                <div class="border-t border-gray-400" />
              <% end %>
              <div class="bg-gray-100 py-2 px-6" id={"call-#{row.sid}"}>
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
                    <span class="font-bold text-red-600">Recorded</span>
                  <% end %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_info({:call_started, sid}, socket) do
    {:noreply, push_redirect(socket, to: "/calls/#{sid}")}
  end

  @impl true
  def handle_info({:call, _sid}, socket) do
    {:noreply, assign_call_history(socket)}
  end

  defp assign_call_history(socket) do
    report = Calls.call_history_report(socket.assigns.user.id)
    assign(socket, :call_history, report)
  end
end

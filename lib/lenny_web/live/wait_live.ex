defmodule LennyWeb.WaitLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.Calls
  alias Lenny.PhoneNumbers

  @impl true
  def mount(_params, %{"user_token" => user_token}, socket) do
    user = Accounts.get_user_by_session_token(user_token)
    phone_number = PhoneNumbers.get_approved_phone_number(user)

    cond do
      phone_number == nil ->
        {:ok, push_redirect(socket, to: "/phone_numbers/new")}

      PhoneNumbers.get_pending_phone_number(user) ->
        {:ok, push_redirect(socket, to: "/phone_numbers/verify")}
        
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
    <div class="container mx-auto pt-4 pb-12 px-2">
      <h1 class="text-3xl font-bold">
        Waiting For Call
      </h1>

      <p class="mt-4">
        This page will automatically refresh when we receive a call from your phone number:
      </p>

      <div class="mt-8 bg-slate-100 border border-slate-600 rounded-lg shadow-md p-4 text-center">
        <h1 class="text-xl font-bold">
          Your Verified Phone Number
        </h1>
        <div class="mt-2 text-green-600 text-xl font-bold tracking-[0.25rem]">
          <span id="approved-number"><%= @phone_number.phone %></span>
        </div>
        <div class="mt-2">
          <%= live_redirect "Change Number", to: "/phone_numbers/new", class: "text-blue-600 text-sm font-bold" %>
        </div>
      </div>

      <h1 class="mt-8 text-3xl font-bold">
        Call History
      </h1>

      <table class="mt-4 w-full">
        <thead>
          <tr>
            <th class="pr-2 text-left">Time</th>
            <th class="pr-2 text-left">Status</th>
            <th class="pr-2 text-left">From</th>
            <th class="pr-2 text-left">To</th>
            <th class="pr-2 text-left">Recorded</th>
          </tr>
        </thead>
        <tbody>
          <%= for row <- @call_history_report do %>
            <tr>
              <td class="pr-2">
                <.link_to_call row={row}>
                  <%= Calendar.strftime(row.started_at, "%c") %>
                </.link_to_call>
              </td>
              <td>
                <.link_to_call row={row}>
                  <%= if row.ended_at == nil do %>
                    <span class="text-green-700">Connected</span>
                  <% else %>
                    <span class="text-red-700">Ended</span>
                  <% end %>
                </.link_to_call>
              
              </td>
              <td class="pr-2">
                <.link_to_call row={row}>
                  <%= row.from %>
                </.link_to_call>
              </td>
              <td class="pr-2">
                <.link_to_call row={row}>
                  <%= row.to %>
                </.link_to_call>
              </td>
              <td class="pr-2">
                <.link_to_call row={row}>
                  <%= inspect row.recorded %>
                </.link_to_call>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  def link_to_call(assigns) do
    ~H"""
    <%= live_redirect to: "/calls/#{@row.sid}" do %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  @impl true
  def handle_info({:call_started, sid}, socket) do
    {:noreply, push_redirect(socket, to: "/calls/#{sid}")}
  end
end

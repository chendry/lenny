defmodule LennyWeb.CallsLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.Calls
  alias Lenny.PhoneNumbers
  alias LennyWeb.ForwardingInstructionsLive

  @impl true
  def mount(_params, %{"user_token" => user_token} = _session, socket) do
    user = Accounts.get_user_by_session_token(user_token)

    verified_phone_number = PhoneNumbers.get_verified_phone_number(user)
    pending_phone_number = PhoneNumbers.get_pending_phone_number(user)

    if sid = Calls.get_sole_unseen_active_call_for_user(user.id) do
      {:ok, push_redirect(socket, to: "/calls/#{sid}")}
    else
      if connected?(socket) do
        if verified_phone_number do
          Phoenix.PubSub.subscribe(Lenny.PubSub, "wait:#{verified_phone_number.phone}")
        end

        Calls.get_active_calls_for_user(user.id)
        |> Enum.each(fn call ->
          Phoenix.PubSub.subscribe(Lenny.PubSub, "call:#{call.sid}")
        end)
      end

      {:ok,
       socket
       |> assign(:user, user)
       |> assign(:verified_phone_number, verified_phone_number)
       |> assign(:pending_phone_number, pending_phone_number)
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
    <%= if @user.confirmed_at == nil do %>
      <h2 class="text-xl font-bold">Please Confirm your Email Address</h2>
      <p class="mt-4">
        We sent a confirmation email to <%= @user.email %>.
      </p>
    <% else %>
    
      <%= if @verified_phone_number == nil do %>
        <h1 class="font-extrabold text-xl">
          Welcome to
          <span class="tracking-wider">
            <span class="text-green-600">938-GOLENNY</span>.<span class="mx-0.5">com</span>!
          </span>
        </h1>

        <div class="mt-4">
          <%= live_render @socket, LennyWeb.PhoneNumberLive, id: "phone_number_live" %>
        </div>
      <% else %>
        <div class="bg-slate-100 border border-slate-600 rounded-lg shadow-md p-4 text-center">
          <h1 class="text-xl font-bold">
            Your Verified Phone Number
          </h1>
          <div class="text-green-600 text-xl font-bold tracking-[0.25rem]">
            <span id="verified-number"><%= @verified_phone_number.phone %></span>
          </div>
        </div>

        <p class="mt-4">
          This page automatically refreshes when we get a call (or a
          forwarded call) from your number.
        </p>

        <div class="mt-10">
          <.live_component
            module={ForwardingInstructionsLive}
            id="forwarding-instructions"
            carrier={@verified_phone_number.carrier["name"]}
          />
        </div>

        <%= if not Enum.empty?(@call_history) do %>
          <h1 class="mt-10 text-lg font-bold">
            Call History
          </h1>

          <div class="flex flex-col -mx-6 sm:mx-0 mt-2 border-y sm:border sm:rounded-lg sm:overflow-hidden border-gray-400">
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
      <% end %>
    <% end %>
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

defmodule LennyWeb.ForwardingInstructionsLive do
  use LennyWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-bold">
        Call Forwarding Instructions
      </h2>
      <%= cond do %>
        <% @carrier =~ "AT&T" -> %>
          <.instructions carrier="AT&T" enable="*61*9384653669#" disable="#61#" />

        <% @carrier =~ "Verizon" -> %>
          <.instructions carrier="Verizon" enable="*719384653669" disable="*73" />

        <% @carrier =~ "T-Mobile" -> %>
          <.instructions carrier="T-Mobile" enable="**004*9384653669*11#" disable="##004#" />

        <% true -> %>
          <p>
            We detected that your mobile carrier is
            <span class="font-bold"><%= @carrier %></span> but we
            don't have instructions on how to automatically forward
            unanswered calls for this carrier.  Please send us an
            email at
            <a class="text-blue-600" href="mailto:support@938golenny.com">
              support@938golenny.com
            </a>
            and we'll get instructions added!
          </p>
      <% end %>
    </div>
    """
  end

  def instructions(assigns) do
    ~H"""
    <p>
      You can automatically forward unanswered calls to Lenny.  Here's how:
    </p>
    <table class="mt-2">
      <tr class="font-bold">
        <td colspan="3">
          <span class="mr-1">
            Carrier
          </span>
          <%= @carrier %>
        </td>
      </tr>
      <tr>
        <td>To enable,</td>
        <td class="text-right pl-1 pr-2">dial</td>
        <td class="pr-2">
          <span class="text-green-600 tracking-widest">
            <a href={"tel:#{@enable}"}><%= @enable %></a>
          </span>
        </td>
      </tr>
      <tr class="pr-2">
        <td>To disable,</td>
        <td class="text-right pl-1 pr-2">dial</td>
        <td>
          <span class="text-green-600 tracking-widest">
            <a href={"tel:#{@disable}"}><%= @disable %></a>
          </span>
        </td>
      </tr>
    </table>
    """
  end

  @impl true
  def handle_event("toggle_visibility", _params, socket) do
    {:noreply, assign(socket, :visible, not socket.assigns.visible)}
  end
end

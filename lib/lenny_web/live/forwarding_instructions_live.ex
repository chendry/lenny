defmodule LennyWeb.ForwardingInstructionsLive do
  use LennyWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-lg font-bold mb-2">
        Call Forwarding Instructions
      </h2>
      <%= cond do %>
        <% @carrier != nil and @carrier =~ "AT&T" -> %>
          <.instructions carrier="AT&T" enable="*61*9384653669#" disable="#61#" />

        <% @carrier != nil and @carrier =~ "Verizon" -> %>
          <.instructions carrier="Verizon" enable="*719384653669" disable="*73" />

        <% @carrier != nil and @carrier =~ "T-Mobile" -> %>
          <.instructions carrier="T-Mobile" enable="**004*9384653669*11#" disable="##004#" />

        <% true -> %>
          <p>
            We detected that your mobile carrier is
            <span class="font-bold"><%= @carrier %></span> but we
            don't have instructions on how to automatically forward
            unanswered calls for this carrier.
          </p>

          <p class="mt-4">
            Please send us an
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
      Using your
      <span class="font-bold"><%= @carrier %></span> device,
      dial the numbers below to enable or disable automatic forwarding
      of unanswered calls to
      <span class="font-bold tracking-wider">938-GOLENNY</span>:
    </p>

    <table class="mt-4 font-bold">
      <tr>
        <td class="pr-2">Enable:</td>
        <td class="pr-2">
          <span class="text-green-600 tracking-widest">
            <a href={"tel:#{@enable}"}><%= @enable %></a>
          </span>
        </td>
      </tr>
      <tr>
        <td class="pr-2">Disable:</td>
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

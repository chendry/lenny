defmodule LennyWeb.ForwardingInstructionsLive do
  use LennyWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, :visible, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <button class="font-bold text-lg text-blue-600" phx-target={@myself} phx-click="toggle">
        Call Forwarding Instructions
      </button>

      <%= if @visible do %>
        <div class="mt-2">
          <%= cond do %>
            <% @carrier != nil and @carrier =~ "AT&T Wireless" -> %>
              <.instructions carrier="AT&T" enable="*61*9384653669#" disable="#61#" />

            <% @carrier != nil and @carrier =~ "Verizon Wireless" -> %>
              <.instructions carrier="Verizon" enable="*719384653669" disable="*73" />

            <% @carrier != nil and @carrier =~ "T-Mobile USA, Inc." -> %>
              <.instructions carrier="T-Mobile" enable="**61*19384653669#" disable="##61#" />

            <% true -> %>
              <p>
                We detected that your mobile carrier is
                <span class="font-bold"><%= @carrier %></span> but we
                don't have instructions on how to automatically forward
                unanswered calls for this carrier.
              </p>

              <p class="mt-4">
                Please
                <a class="text-blue-600" href="mailto:support@938golenny.com">
                contact us
                </a>
                and we'll get instructions added!
              </p>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def instructions(assigns) do
    ~H"""
    <p>
      Using your
      <span class="font-bold"><%= @carrier %></span> device,
      dial (or tap) the numbers below to enable or disable automatic
      forwarding of unanswered calls to
      <span class="font-bold tracking-wider whitespace-nowrap">938-GOLENNY</span>:
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

    <p class="mt-2">
      Not working?
      Please
      <a class="text-blue-600" href="mailto:support@938golenny.com">
        contact us
      </a>
      so we can help!
    </p>
    """
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    {:noreply, assign(socket, :visible, not socket.assigns.visible)}
  end
end

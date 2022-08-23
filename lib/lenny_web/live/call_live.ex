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
    <div class="container mx-auto py-4 px-2">
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
        <div class="mt-4 flex flex-col space-y-4">
          <button class={button_class()} phx-click="say" value={00}>Hello, this is Lenny.</button>
          <button class={button_class()} phx-click="say" value={01}>Sorry, I can barely hear 'ya there.</button>
          <button class={button_class()} phx-click="say" value={02}>Yes, yes yes.</button>
          <button class={button_class()} phx-click="say" value={03}>Oh good! Yes yes yes yes.</button>
          <button class={button_class()} phx-click="say" value={04}>Someone did call last week about the same.  Was that you?</button>
          <button class={button_class()} phx-click="say" value={05}>Sorry, what was your name again?</button>
          <button class={button_class()} phx-click="say" value={06}>Well, it's funny that you call because...</button>
          <button class={button_class()} phx-click="say" value={07}>I couldn't quite catch 'ya there, what was that again?</button>
          <button class={button_class()} phx-click="say" value={08}>Sorry... again?</button>
          <button class={button_class()} phx-click="say" value={09}>Could you say that again please?</button>
          <button class={button_class()} phx-click="say" value={10}>Yes, yes, yes...</button>
          <button class={button_class()} phx-click="say" value={11}>Sorry, which company did you say you were calling from, again?</button>
          <button class={button_class()} phx-click="say" value={12}>The last time call someone called up...</button>
          <button class={button_class()} phx-click="say" value={13}>Since you've put it that way...</button>
          <button class={button_class()} phx-click="say" value={14}>With the world finances the way they are...</button>
          <button class={button_class()} phx-click="say" value={15}>That does sound good, you've been very patient...</button>
          <button class={button_class()} phx-click="say" value={16}>Hello?</button>
          <button class={button_class()} phx-click="say" value={17}>Hello, are you there?</button>
          <button class={button_class()} phx-click="say" value={18}>Sorry, bit of a problem...</button>
        </div>
      <% end %>
    </div>
    """
  end

  defp button_class, do: ~w{ rounded-lg border-2 bg-gray-100 px-2 py-1 border-gray-800 text-blue-600 font-bold }

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

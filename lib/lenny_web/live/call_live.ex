defmodule LennyWeb.CallLive do
  use LennyWeb, :live_view

  alias Lenny.Calls
  alias Lenny.Twilio
  alias LennyWeb.TwiML
  alias LennyWeb.CallLive.Buttons

  @impl true
  def mount(%{"sid" => sid}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Lenny.PubSub, "call:#{sid}")
    end

    {:ok,
     socket
     |> assign(:call, Calls.get_by_sid!(sid))
     |> assign(:audio_ctx_state, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto pt-4 pb-12 px-2">
      <h1 class="text-3xl font-bold" data-sid={@call.sid}>
        Lenny has Answered!
      </h1>

      <p class="mt-2">
        Incoming call from
        <span id="call-from" class="font-bold text-green-600 tracking-widest">
          <%= @call.forwarded_from || @call.from %>
        </span>
      </p>

      <div id="speech" class="flex flex-col justify-center items-center mt-4 h-16 text-green-700 bg-slate-100 border border-slate-800 rounded-md py-1 px-4 text-ellipsis">
        <span><%= @call.speech %></span>
      </div>

      <%= if not @call.ended do %>
        <p class="mt-4 flex flex-col">
          <%= if @audio_ctx_state != "running" do %>
            <button id="start-audio-context-hook" phx-hook="StartAudioContextHook" class={Buttons.audio_class()}>
              <span class="ml-2">
                Start Audio
              </span>
            </button>
          <% else %>
            <button id="stop-audio-context-hook" phx-hook="StopAudioContextHook" class={Buttons.audio_class()}>
              <span class="ml-2">
                Stop Audio
              </span>
            </button>
          <% end %>
        </p>
      <% end %>

      <div id="play-audio-hook" phx-hook="PlayAudioHook" />

      <%= if @call.ended do %>
        <p class="mt-4">
          Call ended.
          <%= live_redirect to: "/wait", class: "text-blue-600" do %>
            Wait for another call
          <% end %>
        </p>
      <% else %>

        <label class="block mt-8">
          <input id="autopilot" type="checkbox" checked={@call.autopilot} phx-click="toggle_autopilot">
          <span class="ml-2">
            Automatically proceed to next sound
          </span>
        </label>

        <div class="mt-8 flex flex-col space-y-4">
          <button {Buttons.say_attrs(@call, 00)}>Hello, this is Lenny.</button>
          <button {Buttons.say_attrs(@call, 01)}>Sorry, I can barely hear 'ya there.</button>
          <button {Buttons.say_attrs(@call, 02)}>Yes, yes yes.</button>
          <button {Buttons.say_attrs(@call, 03)}>Oh good! Yes yes yes yes.</button>
          <button {Buttons.say_attrs(@call, 04)}>Someone did call last week about the same.  Was that you?</button>
          <button {Buttons.say_attrs(@call, 05)}>Sorry, what was your name again?</button>
          <button {Buttons.say_attrs(@call, 06)}>Well, it's funny that you call because...</button>
          <button {Buttons.say_attrs(@call, 07)}>I couldn't quite catch 'ya there, what was that again?</button>
          <button {Buttons.say_attrs(@call, 08)}>Sorry... again?</button>
          <button {Buttons.say_attrs(@call, 09)}>Could you say that again please?</button>
          <button {Buttons.say_attrs(@call, 10)}>Yes, yes, yes...</button>
          <button {Buttons.say_attrs(@call, 11)}>Sorry, which company did you say you were calling from, again?</button>
          <button {Buttons.say_attrs(@call, 12)}>The last time call someone called up...</button>
          <button {Buttons.say_attrs(@call, 13)}>Since you've put it that way...</button>
          <button {Buttons.say_attrs(@call, 14)}>With the world finances the way they are...</button>
          <button {Buttons.say_attrs(@call, 15)}>That does sound good, you've been very patient...</button>
          <button {Buttons.say_attrs(@call, 16)}>Hello?</button>
          <button {Buttons.say_attrs(@call, 17)}>Hello, are you there?</button>
          <button {Buttons.say_attrs(@call, 18)}>Sorry, bit of a problem...</button>
        </div>

        <table class="mt-8 mx-auto">
          <tr>
            <td><button id="dtmf-1" class={Buttons.dtmf_class()} phx-click="dtmf" value="1">1</button></td>
            <td><button id="dtmf-2" class={Buttons.dtmf_class()} phx-click="dtmf" value="2">2</button></td>
            <td><button id="dtmf-3" class={Buttons.dtmf_class()} phx-click="dtmf" value="3">3</button></td>
          </tr>
          <tr>
            <td><button id="dtmf-4" class={Buttons.dtmf_class()} phx-click="dtmf" value="4">4</button></td>
            <td><button id="dtmf-5" class={Buttons.dtmf_class()} phx-click="dtmf" value="5">5</button></td>
            <td><button id="dtmf-6" class={Buttons.dtmf_class()} phx-click="dtmf" value="6">6</button></td>
          </tr>
          <tr>
            <td><button id="dtmf-7" class={Buttons.dtmf_class()} phx-click="dtmf" value="7">7</button></td>
            <td><button id="dtmf-8" class={Buttons.dtmf_class()} phx-click="dtmf" value="8">8</button></td>
            <td><button id="dtmf-9" class={Buttons.dtmf_class()} phx-click="dtmf" value="9">9</button></td>
          </tr>
          <tr>
            <td><button id="dtmf-star" class={Buttons.dtmf_class()} phx-click="dtmf" value="*">*</button></td>
            <td><button id="dtmf-0" class={Buttons.dtmf_class()} phx-click="dtmf" value="0">0</button></td>
            <td><button id="dtmf-pound" class={Buttons.dtmf_class()} phx-click="dtmf" value="#">#</button></td>
          </tr>
        </table>

        <div class="mt-8 flex flex-col">
          <button id="hangup" class={Buttons.hangup_class()} phx-click="hangup">Hang Up</button>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_info({:media, media}, socket) do
    {:noreply, push_event(socket, "media", %{media: media})}
  end

  @impl true
  def handle_info({:call, call}, socket) do
    if call.ended do
      {:noreply,
       socket
       |> put_flash(:info, "Call ended.")
       |> push_redirect(to: "/wait")}
    else
      {:noreply, assign(socket, :call, call)}
    end
  end

  @impl true
  def handle_event("audio_ctx_state", %{"state" => state}, socket) do
    {:noreply, assign(socket, :audio_ctx_state, state)}
  end

  @impl true
  def handle_event("toggle_autopilot", _params, socket) do
    Calls.save_and_broadcast_call(
      socket.assigns.call,
      autopilot: not socket.assigns.call.autopilot
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("say", %{"value" => i}, socket) do
    i = String.to_integer(i)

    Calls.save_and_broadcast_call(
      socket.assigns.call,
      iteration: i
    )

    Twilio.modify_call(
      socket.assigns.call.sid,
      "<Response>#{TwiML.lenny(i)}</Response>"
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("dtmf", %{"value" => <<_>> = key}, socket) do
    Twilio.modify_call(
      socket.assigns.call.sid,
      """
      <Response>
        <Play digits="#{key}" />
        <Pause length="120" />
      </Response>
      """
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("hangup", _params, socket) do
    Calls.save_and_broadcast_call(
      socket.assigns.call.sid,
      ended: true
    )

    Twilio.modify_call(
      socket.assigns.call.sid,
      """
      <Response>
        <Hangup />
      </Response>
      """
    )

    {:noreply, socket}
  end
end

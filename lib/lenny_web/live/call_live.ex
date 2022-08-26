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

    call = Calls.get_by_sid!(sid)

    {:ok,
     socket
     |> assign(:sid, sid)
     |> assign(:call, call)
     |> assign(:iteration, call.iteration)
     |> assign(:speech, call.speech)
     |> assign(:audio_ctx_state, nil)
     |> assign(:ended, call.ended_at != nil)
     |> assign(:autopilot, call.autopilot)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto pt-4 pb-12 px-2">
      <h1 class="text-3xl font-bold" data-sid={@sid}>
        Lenny has Answered!
      </h1>

      <p class="mt-2">
        Incoming call from
        <span id="call-from" class="font-bold text-green-600 tracking-widest">
          <%= @call.forwarded_from || @call.from %>
        </span>
      </p>

      <div id="speech" class="flex flex-col justify-center items-center mt-4 h-16 text-green-700 bg-slate-100 border border-slate-800 rounded-md py-1 px-4 text-ellipsis">
        <span><%= @speech %></span>
      </div>

      <%= if not @ended do %>
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

      <%= if @ended do %>
        <p class="mt-4">
          Call ended.
          <%= live_redirect to: "/wait", class: "text-blue-600" do %>
            Wait for another call
          <% end %>
        </p>
      <% else %>

        <label class="block mt-8">
          <input id="autopilot" type="checkbox" checked={@autopilot} phx-click="toggle_autopilot">
          <span class="ml-2">
            Automatically proceed to next sound
          </span>
        </label>

        <div class="mt-8 flex flex-col space-y-4">
          <button {Buttons.say_attrs(@iteration, 00)}>Hello, this is Lenny.</button>
          <button {Buttons.say_attrs(@iteration, 01)}>Sorry, I can barely hear 'ya there.</button>
          <button {Buttons.say_attrs(@iteration, 02)}>Yes, yes yes.</button>
          <button {Buttons.say_attrs(@iteration, 03)}>Oh good! Yes yes yes yes.</button>
          <button {Buttons.say_attrs(@iteration, 04)}>Someone did call last week about the same.  Was that you?</button>
          <button {Buttons.say_attrs(@iteration, 05)}>Sorry, what was your name again?</button>
          <button {Buttons.say_attrs(@iteration, 06)}>Well, it's funny that you call because...</button>
          <button {Buttons.say_attrs(@iteration, 07)}>I couldn't quite catch 'ya there, what was that again?</button>
          <button {Buttons.say_attrs(@iteration, 08)}>Sorry... again?</button>
          <button {Buttons.say_attrs(@iteration, 09)}>Could you say that again please?</button>
          <button {Buttons.say_attrs(@iteration, 10)}>Yes, yes, yes...</button>
          <button {Buttons.say_attrs(@iteration, 11)}>Sorry, which company did you say you were calling from, again?</button>
          <button {Buttons.say_attrs(@iteration, 12)}>The last time call someone called up...</button>
          <button {Buttons.say_attrs(@iteration, 13)}>Since you've put it that way...</button>
          <button {Buttons.say_attrs(@iteration, 14)}>With the world finances the way they are...</button>
          <button {Buttons.say_attrs(@iteration, 15)}>That does sound good, you've been very patient...</button>
          <button {Buttons.say_attrs(@iteration, 16)}>Hello?</button>
          <button {Buttons.say_attrs(@iteration, 17)}>Hello, are you there?</button>
          <button {Buttons.say_attrs(@iteration, 18)}>Sorry, bit of a problem...</button>
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
  def handle_info({:iteration, i}, socket) do
    {:noreply, assign(socket, :iteration, i)}
  end

  @impl true
  def handle_info({:speech, speech}, socket) do
    {:noreply, assign(socket, :speech, speech)}
  end

  @impl true
  def handle_info(:call_ended, socket) do
    {:noreply,
     socket
     |> put_flash(:info, "Call ended.")
     |> push_redirect(to: "/wait")}
  end

  @impl true
  def handle_event("audio_ctx_state", %{"state" => state}, socket) do
    {:noreply, assign(socket, :audio_ctx_state, state)}
  end

  @impl true
  def handle_event("toggle_autopilot", _params, socket) do
    autopilot = not socket.assigns.autopilot
    Calls.set_autopilot!(socket.assigns.sid, autopilot)
    {:noreply, assign(socket, :autopilot, autopilot)}
  end

  @impl true
  def handle_event("say", %{"value" => i}, socket) do
    i = String.to_integer(i)

    Calls.save_and_broadcast_iteration!(socket.assigns.sid, i)

    Twilio.modify_call(
      socket.assigns.sid,
      "<Response>#{TwiML.lenny(i)}</Response>"
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("dtmf", %{"value" => <<_>> = key}, socket) do
    Twilio.modify_call(
      socket.assigns.sid,
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
    Calls.mark_as_finished!(socket.assigns.sid)

    Twilio.modify_call(
      socket.assigns.sid,
      """
      <Response>
        <Hangup />
      </Response>
      """
    )

    {:noreply, socket}
  end
end

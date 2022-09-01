defmodule LennyWeb.CallLive do
  use LennyWeb, :live_view

  alias Lenny.Accounts
  alias Lenny.Calls
  alias Lenny.Recordings
  alias Lenny.Twilio
  alias LennyWeb.TwiML
  alias LennyWeb.CallLive.Buttons

  @impl true
  def mount(%{"sid" => sid}, session, socket) do
    user =
      case session do
        %{"user_token" => t} -> Accounts.get_user_by_session_token(t)
        _ -> nil
      end

    call = Calls.get_call_for_user!(user, sid)
    recording = user && Recordings.get_recording_for_user(user.id, sid)

    if user do
      Calls.mark_as_seen(
        user.id,
        call.id
      )
    end

    if connected?(socket) do
      Phoenix.PubSub.subscribe(Lenny.PubSub, "call:#{sid}")
      Phoenix.PubSub.subscribe(Lenny.PubSub, "media:#{sid}")
    end

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:call, Calls.get_by_sid!(sid))
     |> assign(:recording, recording)
     |> assign(:audio_ctx_state, nil)
     |> assign(:confirm_delete, false)}
  end

  def breadcrumbs(assigns) do
    ~H"""
    <%= if @user do %>
      <div id="breadcrumbs">
        <%= live_redirect "Calls", to: "/calls" %>
        <span class="breadcrumb-separator" />
        <span>
          <%= Calls.format_timestamp_date(@call.inserted_at) %>
          <%= Calls.format_timestamp_time(@call.inserted_at) %>
        </span>
      </div>
    <% end %>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto pt-4 pb-12 px-6">
      <h1 class="flex flex-row items-center justify-between" data-sid={@call.sid}>
        <div class="text-lg sm:text-xl font-bold">
          Call From
          <span id="call-from" class="font-bold text-green-700 tracking-widest">
            <%= @call.from %>
          </span>
        </div>
        <%= if @recording && @recording.status == "in-progress" do %>
          <span class="text-red-600">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
              <circle cx="10" cy="10" r="10" />
            </svg>
          </span>
          <!-- Recording -->
        <% end %>
      </h1>

      <%= if @call.ended_at == nil do %>
        <div id="speech" class="flex flex-col justify-center items-center mt-4 h-16 font-bold text-green-700 bg-slate-100 border border-slate-800 rounded-md py-1 px-4 text-ellipsis">
          <span><%= @call.speech %></span>
        </div>

        <p class="mt-4 flex flex-col">
          <button id="audio-context-hook" phx-hook="AudioContextHook" class={Buttons.audio_class()}>
            <span class="ml-2">
              <%= if @audio_ctx_state != "running" do %>
                Start Audio
              <% else %>
                Stop Audio
              <% end %>
            </span>
          </button>
        </p>
      <% end %>

      <%= if @call.ended_at do %>
        <div class="mt-4">
        Call ended after
        <span class="font-bold"><%= Calls.format_duration(@call.inserted_at, @call.ended_at) %></span>.
        </div>
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
          <button id="silence" class={Buttons.silence_class(@call)} phx-click="silence">Silence</button>
        </div>

        <div class="mt-8 flex flex-col">
          <button id="hangup" class={Buttons.hangup_class()} phx-click="hangup">Hang Up</button>
        </div>
      <% end %>

      <%= if @recording && @call.ended_at do %>
        <div class="mt-6">
          <%= if @recording.status == "completed" do %>
            <audio controls src={"#{@recording.url}.wav"} class="w-full" />
          <% else %>
            <div class="relative">
              <audio controls class="w-full invisible" />
              <div class="absolute top-1/2 -translate-y-1/2 font-bold text-gray-600 w-full text-center">
                 Processing recording...
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <%= if @call.ended_at && @user do %>
        <div class="text-center mt-8">
          <%= if @confirm_delete == false do %>
            <div class="text-right">
              <button phx-click="confirm_delete" class="font-bold text-red-600">Delete Call</button>
            </div>
          <% else %>
            <p>
              Are you sure you want to delete this call?
            </p>
            <div class="mt-4 flex flex-row justify-center space-x-4">
              <button phx-click="delete" value="1" class={Buttons.confirm_delete_yes_class()}>Yes</button>
              <button phx-click="delete" value="0" class={Buttons.confirm_delete_no_class()}>No</button>
            </div>
          <% end %>
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
    {:noreply, assign(socket, :call, call)}
  end

  @impl true
  def handle_info(:recording, socket) do
    recording =
      Recordings.get_recording_for_user(
        socket.assigns.user.id,
        socket.assigns.call.sid
      )

    {:noreply, assign(socket, :recording, recording)}
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
      iteration: i,
      silence: false
    )

    Twilio.modify_call(
      socket.assigns.call.sid,
      """
      <Response>
        #{TwiML.lenny(i, socket.assigns.call.autopilot)}
      </Response>
      """
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("dtmf", %{"value" => <<_>> = key}, socket) do
    Calls.save_and_broadcast_call(
      socket.assigns.call,
      iteration: nil,
      silence: true
    )

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
  def handle_event("silence", _params, socket) do
    Calls.save_and_broadcast_call(
      socket.assigns.call,
      iteration: nil,
      silence: true
    )

    Twilio.modify_call(
      socket.assigns.call.sid,
      """
      <Response>
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
      ended_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
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

  @impl true
  def handle_event("confirm_delete", _params, socket) do
    {:noreply, assign(socket, :confirm_delete, true)}
  end

  @impl true
  def handle_event("delete", %{"value" => "0"} = _params, socket) do
    {:noreply, assign(socket, :confirm_delete, false)}
  end

  @impl true
  def handle_event("delete", %{"value" => "1"} = _params, socket) do
    Calls.delete_call(
      socket.assigns.user.id,
      socket.assigns.call.id
    )

    {:noreply,
     socket
     |> put_flash(:info, "Call has been deleted.")
     |> push_redirect(to: "/calls")}
  end
end

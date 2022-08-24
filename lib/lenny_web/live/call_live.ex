defmodule LennyWeb.CallLive do
  use LennyWeb, :live_view

  alias Lenny.Calls
  alias Lenny.Twilio
  alias LennyWeb.AudioFileUrls
  alias LennyWeb.TwiML

  @impl true
  def mount(%{"sid" => sid}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Lenny.PubSub, "call:#{sid}")
    end

    call = Calls.get_by_sid!(sid)

    {:ok,
     socket
     |> assign(:sid, sid)
     |> assign(:ended, call.ended_at != nil)
     |> assign(:autopilot, true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto pt-4 pb-12 px-2">
      <p class="mt-4">
        Active call: <%= @sid %>
      </p>

      <%= if @ended do %>
        <p class="mt-4">Call ended.</p>
      <% else %>

        <label class="mt-4">
          <input id="autopilot" type="checkbox" checked={@autopilot} phx-click="toggle_autopilot">
          <span class="ml-2">
            Automatically proceed to next sound
          </span>
        </label>

        <div class="mt-4 flex flex-col space-y-4">
          <button id="say_00" class={say_button_class()} phx-click="say" value={00}>Hello, this is Lenny.</button>
          <button id="say_01" class={say_button_class()} phx-click="say" value={01}>Sorry, I can barely hear 'ya there.</button>
          <button id="say_02" class={say_button_class()} phx-click="say" value={02}>Yes, yes yes.</button>
          <button id="say_03" class={say_button_class()} phx-click="say" value={03}>Oh good! Yes yes yes yes.</button>
          <button id="say_04" class={say_button_class()} phx-click="say" value={04}>Someone did call last week about the same.  Was that you?</button>
          <button id="say_05" class={say_button_class()} phx-click="say" value={05}>Sorry, what was your name again?</button>
          <button id="say_06" class={say_button_class()} phx-click="say" value={06}>Well, it's funny that you call because...</button>
          <button id="say_07" class={say_button_class()} phx-click="say" value={07}>I couldn't quite catch 'ya there, what was that again?</button>
          <button id="say_08" class={say_button_class()} phx-click="say" value={08}>Sorry... again?</button>
          <button id="say_09" class={say_button_class()} phx-click="say" value={09}>Could you say that again please?</button>
          <button id="say_10" class={say_button_class()} phx-click="say" value={10}>Yes, yes, yes...</button>
          <button id="say_11" class={say_button_class()} phx-click="say" value={11}>Sorry, which company did you say you were calling from, again?</button>
          <button id="say_12" class={say_button_class()} phx-click="say" value={12}>The last time call someone called up...</button>
          <button id="say_13" class={say_button_class()} phx-click="say" value={13}>Since you've put it that way...</button>
          <button id="say_14" class={say_button_class()} phx-click="say" value={14}>With the world finances the way they are...</button>
          <button id="say_15" class={say_button_class()} phx-click="say" value={15}>That does sound good, you've been very patient...</button>
          <button id="say_16" class={say_button_class()} phx-click="say" value={16}>Hello?</button>
          <button id="say_17" class={say_button_class()} phx-click="say" value={17}>Hello, are you there?</button>
          <button id="say_18" class={say_button_class()} phx-click="say" value={18}>Sorry, bit of a problem...</button>
        </div>

        <table class="mt-8 mx-auto">
          <tr>
            <td><button id="dtmf-1" class={dtmf_button_class()} phx-click="dtmf" value="1">1</button></td>
            <td><button id="dtmf-2" class={dtmf_button_class()} phx-click="dtmf" value="2">2</button></td>
            <td><button id="dtmf-3" class={dtmf_button_class()} phx-click="dtmf" value="3">3</button></td>
          </tr>
          <tr>
            <td><button id="dtmf-4" class={dtmf_button_class()} phx-click="dtmf" value="4">4</button></td>
            <td><button id="dtmf-5" class={dtmf_button_class()} phx-click="dtmf" value="5">5</button></td>
            <td><button id="dtmf-6" class={dtmf_button_class()} phx-click="dtmf" value="6">6</button></td>
          </tr>
          <tr>
            <td><button id="dtmf-7" class={dtmf_button_class()} phx-click="dtmf" value="7">7</button></td>
            <td><button id="dtmf-8" class={dtmf_button_class()} phx-click="dtmf" value="8">8</button></td>
            <td><button id="dtmf-9" class={dtmf_button_class()} phx-click="dtmf" value="9">9</button></td>
          </tr>
          <tr>
            <td><button id="dtmf-star" class={dtmf_button_class()} phx-click="dtmf" value="*">*</button></td>
            <td><button id="dtmf-0" class={dtmf_button_class()} phx-click="dtmf" value="0">0</button></td>
            <td><button id="dtmf-pound" class={dtmf_button_class()} phx-click="dtmf" value="#">#</button></td>
          </tr>
        </table>

        <div class="mt-8 flex flex-col">
          <button id="hangup" class={hangup_button_class()} phx-click="hangup">Hang Up</button>
        </div>
      <% end %>
    </div>
    """
  end

  defp say_button_class(),
    do: common_button_class() ++ ~w{border-gray-600 from-slate-200 to-slate-300 text-slate-700}

  defp dtmf_button_class, do: say_button_class() ++ ~w{w-10 m-1}

  defp hangup_button_class,
    do:
      common_button_class() ++
        ~w{border-red-600 from-red-500 to-red-600 text-white font-extrabold}

  defp common_button_class(), do: ~w{rounded-lg border-2 px-2 py-1 font-bold bg-gradient-to-b}

  @impl true
  def handle_info(:call_ended, socket) do
    {:noreply, assign(socket, :ended, true)}
  end

  @impl true
  def handle_event("toggle_autopilot", _params, socket) do
    {:noreply, assign(socket, :autopilot, not socket.assigns.autopilot)}
  end

  @impl true
  def handle_event("say", %{"value" => i}, socket) do
    i = String.to_integer(i)

    body =
      if socket.assigns.autopilot do
        TwiML.autopilot_iteration(i)
      else
        """
        <Play>
          #{AudioFileUrls.lenny(i)}
        </Play>
        <Pause length="120" />
        """
      end

    Twilio.modify_call(
      socket.assigns.sid,
      "<Response>#{body}</Response>"
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

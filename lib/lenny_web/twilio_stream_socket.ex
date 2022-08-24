defmodule LennyWeb.TwilioStreamSocket do
  @behaviour Phoenix.Socket.Transport

  def child_spec(_opts) do
    %{id: __MODULE__, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  def connect(state) do
    {:ok, state}
  end

  def init(state) do
    {:ok, state}
  end

  def handle_in({text, _opts}, state) do
    case Jason.decode!(text) do
      %{"event" => "connected"} ->
        {:ok, state}

      %{"event" => "start", "start" => %{"callSid" => call_sid}} ->
        {:ok, Map.put(state, :call_sid, call_sid)}

      %{"media" => %{"chunk" => chunk, "timestamp" => timestamp, "payload" => payload}} ->
        Phoenix.PubSub.broadcast(
          Lenny.PubSub,
          "call:#{state.call_sid}",
          {:media, %{chunk: chunk, timestamp: timestamp, payload: payload}}
        )

        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end

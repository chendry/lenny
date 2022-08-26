defmodule LennyWeb.TwilioController do
  use LennyWeb, :controller

  require Logger

  alias Lenny.Calls
  alias LennyWeb.TwiML

  def incoming(conn, %{"CallSid" => sid} = params) do
    Logger.info("#{__MODULE__}: incoming: #{inspect(params)}")

    call = Calls.create_from_twilio_params!(params)
    from = Calls.get_effective_number(call)

    Phoenix.PubSub.broadcast(Lenny.PubSub, "wait:#{from}", {:call_started, sid})

    spawn fn ->
      Lenny.Twilio.start_recording(sid)
      :timer.sleep(1000)
      Lenny.Twilio.start_recording(sid)
      :timer.sleep(1000)
      Lenny.Twilio.start_recording(sid)
      :timer.sleep(1000)
    end

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(
      200,
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <Response>
        <Start>
          <Stream url="#{stream_url()}" track="both_tracks" />
        </Start>
        #{TwiML.lenny(0)}
      </Response>
      """
    )
  end

  defp stream_url do
    base_url =
      Routes.url(LennyWeb.Endpoint)
      |> String.replace_leading("https", "wss")
      |> String.replace_leading("http", "ws")

    "#{base_url}/twilio/stream/websocket"
  end

  def call_status(conn, %{"CallSid" => sid} = params) do
    Logger.info("#{__MODULE__}: call_status: #{inspect(params)}")

    if params["CallStatus"] == "completed" do
      Calls.save_and_broadcast_call(sid, ended_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    end

    send_resp(conn, 200, "OK")
  end

  def recording_status(conn, %{"CallSid" => _sid} = params) do
    Logger.info("#{__MODULE__}: recording_status: #{inspect(params)}")
    send_resp(conn, 200, "OK")
  end

  def gather(conn, %{"CallSid" => sid, "i" => i} = params) do
    Logger.info("#{__MODULE__}: gather: #{inspect(params)}")

    i = String.to_integer(i)
    call = Calls.get_by_sid!(sid)

    {twiml, iteration} =
      if call.autopilot do
        i = rem(i + 1, 19)
        {TwiML.lenny(i), i}
      else
        {TwiML.gather(120, i), i}
      end

    Calls.save_and_broadcast_call(
      call,
      iteration: iteration,
      speech: params["SpeechResult"]
    )

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(
      200,
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <Response>
        #{twiml}
      </Response>
      """
    )
  end
end

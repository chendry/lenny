defmodule LennyWeb.TwilioController do
  use LennyWeb, :controller

  require Logger

  alias Lenny.Calls
  alias Lenny.Recordings
  alias Lenny.Twilio
  alias LennyWeb.TwiML

  def incoming(conn, %{"CallSid" => sid} = params) do
    Logger.info("#{__MODULE__}: incoming: #{inspect(params)}")

    call = Calls.create_from_twilio_params!(params)

    if Calls.should_record_call?(call) do
      Twilio.start_recording(sid)
    end

    from = Calls.get_effective_from(call)

    Phoenix.PubSub.broadcast(Lenny.PubSub, "wait:#{from}", {:call_started, sid})

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

  def call_status(conn, %{"CallSid" => sid} = params) do
    Logger.info("#{__MODULE__}: call_status: #{inspect(params)}")

    if params["CallStatus"] == "completed" do
      Calls.save_and_broadcast_call(sid, ended_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
    end

    send_resp(conn, 200, "OK")
  end

  def recording_status(conn, %{"CallSid" => sid} = params) do
    Logger.info("#{__MODULE__}: recording_status: #{inspect(params)}")
    Recordings.insert_or_update_from_twilio_params!(params)
    Phoenix.PubSub.broadcast(Lenny.PubSub, "call:#{sid}", :recording)
    send_resp(conn, 200, "OK")
  end

  defp stream_url do
    base_url =
      Routes.url(LennyWeb.Endpoint)
      |> String.replace_leading("https", "wss")
      |> String.replace_leading("http", "ws")

    "#{base_url}/twilio/stream/websocket"
  end
end

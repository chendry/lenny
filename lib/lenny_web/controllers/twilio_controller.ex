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
      Phoenix.PubSub.broadcast(Lenny.PubSub, "call:#{sid}", :call_ended)
      Calls.mark_as_finished!(sid)
    end

    send_resp(conn, 200, "OK")
  end

  def gather(conn, %{"CallSid" => sid, "i" => i} = params) do
    Logger.info("#{__MODULE__}: gather: #{inspect(params)}")

    i = String.to_integer(i)

    if speech = params["SpeechResult"] do
      Calls.save_and_broadcast_speech!(sid, speech)
    end

    {twiml, i} =
      if Calls.get_autopilot(sid) do
        i = rem(i + 1, 19)
        {TwiML.lenny(i), i}
      else
        {TwiML.gather(120, i), i}
      end

    Calls.save_and_broadcast_iteration!(sid, i)

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

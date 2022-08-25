defmodule LennyWeb.AutopilotController do
  use LennyWeb, :controller

  require Logger

  alias LennyWeb.TwiML

  def iteration(conn, %{"CallSid" => sid, "i" => i} = params) do
    Logger.info("#{__MODULE__}: iteration: #{inspect(params)}")

    i = String.to_integer(i)

    if speech = params["SpeechResult"] do
      Phoenix.PubSub.broadcast(Lenny.PubSub, "call:#{sid}", {:speech_result, speech})
    end

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(
      200,
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <Response>
        #{TwiML.autopilot_iteration(i)}
      </Response>
      """
    )
  end
end

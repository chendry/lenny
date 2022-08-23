defmodule LennyWeb.TwilioController do
  use LennyWeb, :controller

  require Logger

  alias Lenny.Calls
  alias LennyWeb.TwiML

  def incoming(conn, %{"CallSid" => sid} = params) do
    Logger.info("#{__MODULE__}: incoming: #{inspect(params)}")

    call = Calls.create_from_twilio_params!(params)
    from = call.forwarded_from || call.from

    Phoenix.PubSub.broadcast(Lenny.PubSub, "call:#{from}", {:call, :started, sid})

    conn
    |> put_resp_content_type("text/xml")
    |> send_resp(
      200,
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <Response>
        #{TwiML.autopilot_iteration(0)}
      </Response>
      """
    )
  end

  def call_status(conn, %{"CallSid" => sid} = params) do
    Logger.info("#{__MODULE__}: call_status: #{inspect(params)}")

    call = Calls.get_by_sid!(sid)
    from = call.forwarded_from || call.from

    if params["CallStatus"] == "completed" do
      Phoenix.PubSub.broadcast(Lenny.PubSub, "call:#{from}", {:call, :ended})
      Calls.mark_as_finished!(sid)
    end

    send_resp(conn, 200, "OK")
  end
end

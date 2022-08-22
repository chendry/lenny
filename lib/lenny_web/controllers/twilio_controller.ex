defmodule LennyWeb.TwilioController do
  use LennyWeb, :controller

  require Logger

  alias LennyWeb.TwiML

  def incoming(conn, %{"CallSid" => _sid} = params) do
    Logger.info("#{__MODULE__}: incoming: #{inspect(params)}")

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

  def call_status(conn, params) do
    Logger.info("#{__MODULE__}: call_status: #{inspect(params)}")
    send_resp(conn, 200, "OK")
  end
end

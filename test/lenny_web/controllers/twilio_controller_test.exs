defmodule LennyWeb.TwilioControllerTest do
  use LennyWeb.ConnCase

  test "POST /twilio/incoming", %{conn: conn} do
    params = %{
      "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "ApiVersion" => "2010-04-01",
      "CallSid" => "CAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "CallStatus" => "ringing",
      "CallToken" => "...",
      "Called" => "+19384653669",
      "CalledCity" => "",
      "CalledCountry" => "US",
      "CalledState" => "AL",
      "CalledZip" => "",
      "Caller" => "+13126180256",
      "CallerCity" => "CHICAGO",
      "CallerCountry" => "US",
      "CallerState" => "IL",
      "CallerZip" => "60605",
      "Direction" => "inbound",
      "From" => "+13126180256",
      "FromCity" => "CHICAGO",
      "FromCountry" => "US",
      "FromState" => "IL",
      "FromZip" => "60605",
      "To" => "+19384653669",
      "ToCity" => "",
      "ToCountry" => "US",
      "ToState" => "AL",
      "ToZip" => ""
    }

    conn = post(conn, "/twilio/incoming", params)
    assert response(conn, 200) =~ "lenny_01.mp3"
    assert response(conn, 200) =~ "/autopilot/1"
  end

  test "POST /twilio/status/call", %{conn: conn} do
    params = %{}
    conn = post(conn, "/twilio/status/call", params)
    assert response(conn, 200) == "OK"
  end
end

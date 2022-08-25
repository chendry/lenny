defmodule LennyWeb.AutopilotControllerTest do
  use LennyWeb.ConnCase

  test "POST /autopilot/1", %{conn: conn} do
    params = %{
      "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "ApiVersion" => "2010-04-01",
      "CallSid" => "CAc1df328a4f55e68e333ab387c1dd8e87",
      "CallStatus" => "in-progress",
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
      "Confidence" => "0.9128386",
      "Direction" => "inbound",
      "From" => "+13126180256",
      "FromCity" => "CHICAGO",
      "FromCountry" => "US",
      "FromState" => "IL",
      "FromZip" => "60605",
      "Language" => "en-US",
      "SpeechResult" => "Banana.",
      "To" => "+19384653669",
      "ToCity" => "",
      "ToCountry" => "US",
      "ToState" => "AL",
      "ToZip" => ""
    }

    conn = post(conn, "/twilio/autopilot/1", params)
    assert response(conn, 200) =~ "lenny_01.mp3"
    refute response(conn, 200) =~ "lenny_02.mp3"
    assert response(conn, 200) =~ "/twilio/autopilot/2"
  end

  test "POST /autopilot/2", %{conn: conn} do
    params = %{
      "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "ApiVersion" => "2010-04-01",
      "CallSid" => "CAc1df328a4f55e68e333ab387c1dd8e87",
      "CallStatus" => "in-progress",
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
      "Confidence" => "0.9128386",
      "Direction" => "inbound",
      "From" => "+13126180256",
      "FromCity" => "CHICAGO",
      "FromCountry" => "US",
      "FromState" => "IL",
      "FromZip" => "60605",
      "Language" => "en-US",
      "SpeechResult" => "Apple.",
      "To" => "+19384653669",
      "ToCity" => "",
      "ToCountry" => "US",
      "ToState" => "AL",
      "ToZip" => ""
    }

    conn = post(conn, "/twilio/autopilot/2", params)
    assert response(conn, 200) =~ "lenny_02.mp3"
    refute response(conn, 200) =~ "lenny_03.mp3"
    assert response(conn, 200) =~ "/twilio/autopilot/3"
  end
end

defmodule LennyWeb.AutopilotControllerTest do
  use LennyWeb.ConnCase

  import Lenny.CallsFixtures

  test "POST /twilio/gather/1 with autopilot", %{conn: conn} do
    call_fixture(sid: "CAc1df328a4f55e68e333ab387c1dd8e87", autopilot: true)

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

    response =
      conn
      |> post("/twilio/gather/1", params)
      |> response(200)

    refute response =~ "lenny_01.mp3"
    assert response =~ "lenny_02.mp3"
    assert response =~ "/twilio/gather/2"
  end

  test "POST /twilio/lenny/1 without autopilot", %{conn: conn} do
    call_fixture(sid: "CAc1df328a4f55e68e333ab387c1dd8e87", autopilot: false)

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

    response =
      conn
      |> post("/twilio/gather/1", params)
      |> response(200)

    refute response =~ ".mp3"
    assert response =~ "/twilio/gather/1"
  end
end

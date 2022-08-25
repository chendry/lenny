defmodule LennyWeb.TwilioControllerTest do
  use LennyWeb.ConnCase

  alias Lenny.Repo
  alias Lenny.Calls.Call

  import Lenny.CallsFixtures

  test "POST /twilio/incoming", %{conn: conn} do
    params = %{
      "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "ApiVersion" => "2010-04-01",
      "CallSid" => "CAcd3d0f9f054366f89712ef4278630247",
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

    xml =
      conn
      |> post("/twilio/incoming", params)
      |> response(200)

    assert xml =~ "lenny_00.mp3"
    assert xml =~ "/twilio/gather/0"
    assert xml =~ "ws://localhost/twilio/stream/websocket"

    assert Repo.get_by(Call, sid: "CAcd3d0f9f054366f89712ef4278630247") != nil
  end

  test "POST /twilio/status/call to end call", %{conn: conn} do
    call = call_fixture(sid: "CA1ec1bf246aa203e56716b602d6f6c8c9")

    params = %{
      "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      "ApiVersion" => "2010-04-01",
      "CallDuration" => "28",
      "CallSid" => "CA1ec1bf246aa203e56716b602d6f6c8c9",
      "CallStatus" => "completed",
      "CallbackSource" => "call-progress-events",
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
      "Duration" => "1",
      "From" => "+13126180256",
      "FromCity" => "CHICAGO",
      "FromCountry" => "US",
      "FromState" => "IL",
      "FromZip" => "60605",
      "SequenceNumber" => "0",
      "Timestamp" => "Mon, 22 Aug 2022 11:56:46 +0000",
      "To" => "+19384653669",
      "ToCity" => "",
      "ToCountry" => "US",
      "ToState" => "AL",
      "ToZip" => ""
    }

    conn = post(conn, "/twilio/status/call", params)
    assert conn.status == 200

    call = Repo.get(Call, call.id)
    assert call.ended_at != nil
  end

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

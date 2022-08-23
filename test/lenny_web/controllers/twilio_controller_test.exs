defmodule LennyWeb.TwilioControllerTest do
  use LennyWeb.ConnCase

  alias Lenny.Repo
  alias Lenny.Calls.Call

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
    assert response(conn, 200) =~ "lenny_00.mp3"
    assert response(conn, 200) =~ "/autopilot/1"
  end

  test "POST /twilio/status/call to end call", %{conn: conn} do
    call =
      %Call{
        sid: "CA1ec1bf246aa203e56716b602d6f6c8c9",
        from: "13126180256",
        to: "19384653669",
        params: %{}
      }
      |> Repo.insert!()

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
end

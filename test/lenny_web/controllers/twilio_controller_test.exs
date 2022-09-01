defmodule LennyWeb.TwilioControllerTest do
  use LennyWeb.ConnCase

  alias Lenny.Repo
  alias Lenny.Calls.Call
  alias Lenny.Recordings.Recording

  import Lenny.AccountsFixtures
  import Lenny.CallsFixtures
  import Lenny.PhoneNumbersFixtures
  import Lenny.RecordingsFixtures

  test "POST /twilio/incoming", %{conn: conn} do
    Mox.expect(Lenny.TwilioMock, :send_sms, fn _, _ -> :ok end)

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
    assert response =~ ~s{/twilio/gather/2"}
  end

  test "POST /twilio/gather/1 without autopilot", %{conn: conn} do
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
    assert response =~ ~s{/twilio/gather/1"}
  end

  test "POST /twilio/gather/18 with plays lenny_00.mp3", %{conn: conn} do
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
      "SpeechResult" => "Apple.",
      "To" => "+19384653669",
      "ToCity" => "",
      "ToCountry" => "US",
      "ToState" => "AL",
      "ToZip" => ""
    }

    response =
      conn
      |> post("/twilio/gather/18", params)
      |> response(200)

    assert response =~ "lenny_00.mp3"
    assert response =~ "/twilio/gather/0"
  end

  test "POST /twilio/incoming records call when user has recording enabled", %{conn: conn} do
    Mox.expect(Lenny.TwilioMock, :send_sms, fn _, _ -> :ok end)

    user = user_fixture(record_calls: true)
    phone_number_fixture(user, phone: "+13125550001", verified_at: ~N[2022-08-27 20:06:08])

    params = %{
      "CallSid" => "CAcd3d0f9f054366f89712ef4278630247",
      "From" => "+13125550001",
      "To" => "+19384653669"
    }

    Lenny.TwilioMock
    |> Mox.expect(:start_recording, fn "CAcd3d0f9f054366f89712ef4278630247" -> :ok end)

    post(conn, "/twilio/incoming", params)
  end

  test "POST /twilio/status/recording creates a recording", %{conn: conn} do
    post(
      conn,
      "/twilio/status/recording",
      %{
        "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        "CallSid" => "CAcfcd3db14f143b00141b45cd0ffa3d65",
        "RecordingChannels" => "1",
        "RecordingSid" => "REafd66b74b49551a69593c41da1d638c0",
        "RecordingSource" => "StartCallRecordingAPI",
        "RecordingStartTime" => "Sat, 27 Aug 2022 11:03:41 +0000",
        "RecordingStatus" => "in-progress",
        "RecordingTrack" => "both",
        "RecordingUrl" =>
          "https://api.twilio.com/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Recordings/REafd66b74b49551a69593c41da1d638c0"
      }
    )

    assert Repo.get_by(Recording, sid: "CAcfcd3db14f143b00141b45cd0ffa3d65")
  end

  test "POST /twilio/status/recording updates recordings", %{conn: conn} do
    recordings_fixture(
      sid: "CAcfcd3db14f143b00141b45cd0ffa3d65",
      status: "in-progress",
      url: "https://foo.bar/",
      params: %{}
    )

    post(
      conn,
      "/twilio/status/recording",
      %{
        "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        "CallSid" => "CAcfcd3db14f143b00141b45cd0ffa3d65",
        "ErrorCode" => "0",
        "RecordingChannels" => "1",
        "RecordingDuration" => "10",
        "RecordingSid" => "REafd66b74b49551a69593c41da1d638c0",
        "RecordingSource" => "StartCallRecordingAPI",
        "RecordingStartTime" => "Sat, 27 Aug 2022 11:03:41 +0000",
        "RecordingStatus" => "completed",
        "RecordingTrack" => "both",
        "RecordingUrl" =>
          "https://api.twilio.com/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Recordings/REafd66b74b49551a69593c41da1d638c0"
      }
    )

    recording = Repo.get_by(Recording, sid: "CAcfcd3db14f143b00141b45cd0ffa3d65")
    assert recording.status == "completed"
  end

  test "sms links are sent to for non-forwarded incoming calls", %{conn: conn} do
    Lenny.TwilioMock
    |> Mox.expect(:send_sms, fn "+13125551234", body ->
      assert body =~ "/calls/CA001"
      :ok
    end)

    conn
    |> post(
      "/twilio/incoming",
      %{
        "CallSid" => "CA001",
        "From" => "+13125551234",
        "To" => "+19384653669"
      }
    )
    |> response(200)
  end

  test "sms links are sent to for forwarded incoming calls", %{conn: conn} do
    Lenny.TwilioMock
    |> Mox.expect(:send_sms, fn "+13125551234", body ->
      assert body =~ "/calls/CA001"
      :ok
    end)

    conn
    |> post(
      "/twilio/incoming",
      %{
        "CallSid" => "CA001",
        "ForwardedFrom" => "+13125551234",
        "From" => "+19998887777",
        "To" => "+19384653669"
      }
    )
    |> response(200)
  end
end

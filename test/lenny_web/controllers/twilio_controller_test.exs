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

    xml =
      conn
      |> post("/twilio/incoming", %{
        "CallSid" => "CA001",
        "From" => "+13126180256",
        "To" => "+19384653669"
      })
      |> response(200)

    assert xml =~ "lenny_00.mp3"
    assert xml =~ "/twilio/gather/0"
    assert xml =~ "ws://localhost/twilio/stream/websocket"

    assert Repo.get_by(Call, sid: "CA001") != nil
  end

  test "POST /twilio/incoming sends SMS when user has send_sms enabled", %{conn: conn} do
    Mox.expect(Lenny.TwilioMock, :send_sms, fn _, _ -> :ok end)

    user = user_fixture(send_sms: true)
    phone_number_fixture(user, phone: "+13125554444")

    post(conn, "/twilio/incoming", %{
      "CallSid" => "CA002",
      "From" => "+13125554444",
      "To" => "+19384653669"
    })
  end

  test "POST /twilio/incoming does not send SMS when user has send_sms disabled", %{conn: conn} do
    user = user_fixture(send_sms: false)
    phone_number_fixture(user, phone: "+13125554444")

    post(conn, "/twilio/incoming", %{
      "CallSid" => "CA003",
      "From" => "+13125554444",
      "To" => "+19384653669"
    })
  end

  test "POST /twilio/status/call to end call", %{conn: conn} do
    call = call_fixture(sid: "CA004")

    conn =
      post(conn, "/twilio/status/call", %{
        "CallSid" => "CA004",
        "CallStatus" => "completed"
      })

    assert conn.status == 200
    assert Repo.reload!(call).ended_at != nil
  end

  test "POST /twilio/gather/1 with autopilot", %{conn: conn} do
    call_fixture(sid: "CA005", autopilot: true)

    response =
      conn
      |> post("/twilio/gather/1", %{"CallSid" => "CA005"})
      |> response(200)

    refute response =~ "lenny_01.mp3"
    assert response =~ "lenny_02.mp3"
    assert response =~ ~s{/twilio/gather/2"}
  end

  test "POST /twilio/gather/1 without autopilot", %{conn: conn} do
    call_fixture(sid: "CA006", autopilot: false)

    response =
      conn
      |> post("/twilio/gather/1", %{"CallSid" => "CA006"})
      |> response(200)

    refute response =~ ".mp3"
    assert response =~ ~s{/twilio/gather/1"}
  end

  test "POST /twilio/gather/18 with plays lenny_00.mp3", %{conn: conn} do
    call_fixture(sid: "CA007", autopilot: true)

    response =
      conn
      |> post("/twilio/gather/18", %{"CallSid" => "CA007"})
      |> response(200)

    assert response =~ "lenny_00.mp3"
    assert response =~ "/twilio/gather/0"
  end

  test "POST /twilio/incoming records call when user has recording enabled", %{conn: conn} do
    user = user_fixture(record_calls: true)
    phone_number_fixture(user, phone: "+13125550001", verified_at: ~N[2022-08-27 20:06:08])

    Lenny.TwilioMock
    |> Mox.expect(:send_sms, fn _, _ -> :ok end)
    |> Mox.expect(:start_recording, fn "CA008" -> :ok end)

    post(conn, "/twilio/incoming", %{
      "CallSid" => "CA008",
      "From" => "+13125550001",
      "To" => "+19384653669"
    })
  end

  test "POST /twilio/status/recording creates a recording", %{conn: conn} do
    post(conn, "/twilio/status/recording", %{
      "CallSid" => "CA009",
      "RecordingUrl" => "https://example.com/CA009"
    })

    recording = Repo.get_by(Recording, sid: "CA009")
    assert recording.url == "https://example.com/CA009"
  end

  test "POST /twilio/status/recording updates recordings", %{conn: conn} do
    recording =
      recordings_fixture(
        sid: "CA010",
        status: "in-progress",
        url: "https://example.com/CA010",
        params: %{}
      )

    post(conn, "/twilio/status/recording", %{
      "CallSid" => "CA010",
      "RecordingStatus" => "completed",
      "RecordingUrl" => "https://example.com/CA010.wav"
    })

    recording = Repo.reload!(recording)

    assert recording.status == "completed"
    assert recording.url == "https://example.com/CA010.wav"
  end

  test "sms links are sent to 'From' for non-forwarded incoming calls", %{conn: conn} do
    Mox.expect(Lenny.TwilioMock, :send_sms, fn "+13125551234", body ->
      assert body =~ "/calls/CA011"
      :ok
    end)

    post(conn, "/twilio/incoming", %{
      "CallSid" => "CA011",
      "From" => "+13125551234",
      "To" => "+19384653669"
    })
  end

  test "sms links are sent to 'ForwardedFrom' for forwarded incoming calls", %{conn: conn} do
    Mox.expect(Lenny.TwilioMock, :send_sms, fn "+13125551234", body ->
      assert body =~ "/calls/CA012"
      :ok
    end)

    post(conn, "/twilio/incoming", %{
      "CallSid" => "CA012",
      "ForwardedFrom" => "+13125551234",
      "From" => "+19998887777",
      "To" => "+19384653669"
    })
  end
end

defmodule LennyWeb.CallLiveTest do
  use LennyWeb.ConnCase

  import Phoenix.LiveViewTest
  import Lenny.PhoneNumbersFixtures
  import Lenny.CallsFixtures

  alias Lenny.Repo
  alias Lenny.Calls.Call

  setup [:register_and_log_in_user]

  test "call status webhook with CallStatus=completed ends the call", %{conn: conn} do
    call = call_fixture(sid: "CAXXX")

    {:ok, live_view, html} = live(conn, "/calls/CAXXX")
    assert html =~ ~S(data-sid="CAXXX")

    Phoenix.ConnTest.build_conn()
    |> post("/twilio/status/call", %{"CallSid" => "CAXXX", "CallStatus" => "completed"})

    flash = assert_redirect(live_view, "/wait")
    assert flash["info"] == "Call ended."

    assert Repo.get(Call, call.id).ended_at != nil
  end

  test "push the say buttons during a call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")
    call_fixture(sid: "CAXXXX1234", from: "+13126180256")

    {:ok, live_view, _html} = live(conn, "/calls/CAXXXX1234")

    Lenny.TwilioMock
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ "lenny_01.mp3"
      assert twiml =~ "autopilot"
    end)
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ "lenny_03.mp3"
      assert twiml =~ "autopilot"
    end)

    _html =
      live_view
      |> element("button#say_01")
      |> render_click()

    _html =
      live_view
      |> element("button#say_03", "")
      |> render_click()
  end

  test "push the say buttons with autopilot off during a call", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")
    call_fixture(sid: "CAXXXX1234", from: "+13126180256")

    {:ok, live_view, _html} = live(conn, "/calls/CAXXXX1234")

    Lenny.TwilioMock
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ "lenny_07.mp3"
      refute twiml =~ "autopilot"
    end)

    _html =
      live_view
      |> element("#autopilot")
      |> render_click()

    refute render(element(live_view, "#autopilot")) =~ "checked"

    _html =
      live_view
      |> element("button#say_07", "")
      |> render_click()
  end

  test "push the DTMF buttons", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")
    call_fixture(sid: "CAXXXX1234", from: "+13126180256")

    {:ok, live_view, _html} = live(conn, "/calls/CAXXXX1234")

    Lenny.TwilioMock
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ ~r{<Response>\s*<Play digits="1"}
    end)
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ ~r{<Response>\s*<Play digits="#"}
    end)

    _html =
      live_view
      |> element("#dtmf-1")
      |> render_click()

    _html =
      live_view
      |> element("#dtmf-pound")
      |> render_click()
  end

  test "hang up", %{conn: conn, user: user} do
    phone_number_fixture(user, phone: "+13126180256")
    call = call_fixture(sid: "CAXXXX1234", from: "+13126180256")

    {:ok, live_view, _html} = live(conn, "/calls/CAXXXX1234")

    Lenny.TwilioMock
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ "<Hangup />"
    end)

    assert Repo.get(Call, call.id).ended_at == nil

    _html =
      live_view
      |> element("#hangup")
      |> render_click()

    assert Repo.get(Call, call.id).ended_at != nil
  end

  test "visit a call that has ended", %{conn: conn} do
    call_fixture(sid: "CA007", ended_at: ~N[2022-08-24 14:03:31])

    {:ok, _live_view, html} = live(conn, "/calls/CA007")
    assert html =~ "Call ended"
    refute html =~ "Start Audio"
  end

  test "show what the person says during autopilot", %{conn: conn} do
    call_fixture(sid: "CA165c28bffa7817b0ccd857fa1adc124c")

    {:ok, live_view, html} = live(conn, "/calls/CA165c28bffa7817b0ccd857fa1adc124c")

    refute html =~ "I'm a banana"

    Phoenix.ConnTest.build_conn()
    |> post(
      "/twilio/autopilot/3",
      %{
        "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        "ApiVersion" => "2010-04-01",
        "CallSid" => "CA165c28bffa7817b0ccd857fa1adc124c",
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
        "Confidence" => "0.91283864",
        "Direction" => "inbound",
        "From" => "+13126180256",
        "FromCity" => "CHICAGO",
        "FromCountry" => "US",
        "FromState" => "IL",
        "FromZip" => "60605",
        "Language" => "en-US",
        "SpeechResult" => "I'm a banana.",
        "To" => "+19384653669",
        "ToCity" => "",
        "ToCountry" => "US",
        "ToState" => "AL",
        "ToZip" => ""
      }
    )

    html =
      live_view
      |> element("#speech-result")
      |> render()
    
    assert html =~ "I&#39;m a banana."
  end

  test "show what the person says without autopilot", %{conn: conn} do
    call_fixture(sid: "CA165c28bffa7817b0ccd857fa1adc124c")

    {:ok, live_view, html} = live(conn, "/calls/CA165c28bffa7817b0ccd857fa1adc124c")

    refute html =~ "We only have yardsticks"

    Phoenix.ConnTest.build_conn()
    |> post(
      "/twilio/gather",
      %{
        "AccountSid" => "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
        "ApiVersion" => "2010-04-01",
        "CallSid" => "CA165c28bffa7817b0ccd857fa1adc124c",
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
        "Confidence" => "0.91283864",
        "Direction" => "inbound",
        "From" => "+13126180256",
        "FromCity" => "CHICAGO",
        "FromCountry" => "US",
        "FromState" => "IL",
        "FromZip" => "60605",
        "Language" => "en-US",
        "SpeechResult" => "We only have yardsticks.",
        "To" => "+19384653669",
        "ToCity" => "",
        "ToCountry" => "US",
        "ToState" => "AL",
        "ToZip" => ""
      }
    )

    html =
      live_view
      |> element("#speech-result")
      |> render()
    
    assert html =~ "We only have yardsticks."
  end
end

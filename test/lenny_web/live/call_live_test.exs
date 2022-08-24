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

    html = render(live_view)
    assert html =~ "Call ended."
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
end

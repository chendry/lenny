defmodule LennyWeb.CallLiveTest do
  use LennyWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Lenny.Repo
  alias Lenny.Calls.Call
  alias Lenny.PhoneNumbers.PhoneNumber

  setup [:register_and_log_in_user]

  test "handle a call", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+13126180256",
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
    |> Repo.insert!()

    {:ok, lenny_live, html} = live(conn, "/calls")
    assert html =~ "Waiting for a forwarded call..."
    refute html =~ "Active call:"

    Phoenix.ConnTest.build_conn()
    |> post("/twilio/incoming", %{"CallSid" => "CAXXX", "From" => "+13126180256"})

    html = render(lenny_live)
    refute html =~ "Waiting for a forwarded call..."
    assert html =~ "Active call: CAXXX"

    Phoenix.ConnTest.build_conn()
    |> post("/twilio/status/call", %{"CallSid" => "CAXXX", "CallStatus" => "completed"})

    html = render(lenny_live)
    assert html =~ "Waiting for a forwarded call..."
    refute html =~ "Active call: CAXXX"
  end

  test "load page with an active call in progress", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+13126180256",
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
    |> Repo.insert!()

    %Call{
      sid: "CAXXXX1234",
      from: "+13126180256",
      to: "+18384653669",
      ended_at: nil,
    }
    |> Repo.insert!()

    {:ok, _lenny_live, html} = live(conn, "/calls")

    refute html =~ "Waiting for a forwarded call..."
    assert html =~ "Active call: CAXXXX1234"
  end

  test "push the say buttons during a call", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+13126180256",
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
    |> Repo.insert!()

    %Call{
      sid: "CAXXXX1234",
      from: "+13126180256",
      to: "+18384653669",
      ended_at: nil,
    }
    |> Repo.insert!()

    {:ok, lenny_live, _html} = live(conn, "/calls")

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
      lenny_live
      |> element("button#say_01")
      |> render_click()

    _html =
      lenny_live
      |> element("button#say_03", "")
      |> render_click()
  end

  test "push the say buttons with autopilot off during a call", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+13126180256",
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
    |> Repo.insert!()

    %Call{
      sid: "CAXXXX1234",
      from: "+13126180256",
      to: "+18384653669",
      ended_at: nil,
    }
    |> Repo.insert!()

    {:ok, lenny_live, _html} = live(conn, "/calls")

    Lenny.TwilioMock
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ "lenny_07.mp3"
      refute twiml =~ "autopilot"
    end)

    _html =
      lenny_live
      |> element("#autopilot")
      |> render_click()

    refute render(element(lenny_live, "#autopilot")) =~ "checked"

    _html =
      lenny_live
      |> element("button#say_07", "")
      |> render_click()
  end

  test "push the DTMF buttons", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+13126180256",
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
    |> Repo.insert!()

    %Call{
      sid: "CAXXXX1234",
      from: "+13126180256",
      to: "+18384653669",
      ended_at: nil,
    }
    |> Repo.insert!()

    {:ok, lenny_live, _html} = live(conn, "/calls")

    Lenny.TwilioMock
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ ~r{<Response>\s*<Play digits="1"}
    end)
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ ~r{<Response>\s*<Play digits="#"}
    end)

    _html =
      lenny_live
      |> element("#dtmf-1")
      |> render_click()

    _html =
      lenny_live
      |> element("#dtmf-pound")
      |> render_click()
  end

  test "hang up", %{conn: conn, user: user} do
    %PhoneNumber{
      user_id: user.id,
      phone: "+13126180256",
      verified_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    }
    |> Repo.insert!()

    %Call{
      sid: "CAXXXX1234",
      from: "+13126180256",
      to: "+18384653669",
      ended_at: nil,
    }
    |> Repo.insert!()

    {:ok, lenny_live, _html} = live(conn, "/calls")

    Lenny.TwilioMock
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ "<Hangup />"
    end)

    _html =
      lenny_live
      |> element("#hangup")
      |> render_click()
  end
end

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

  test "push the say buttotns during a call", %{conn: conn, user: user} do
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
      assert twiml =~ "lenny_02.mp3"
    end)
    |> Mox.expect(:modify_call, fn "CAXXXX1234", twiml ->
      assert twiml =~ "lenny_04.mp3"
    end)

    _html =
      lenny_live
      |> element("button", "01")
      |> render_click()

    _html =
      lenny_live
      |> element("button", "03")
      |> render_click()
  end
end
